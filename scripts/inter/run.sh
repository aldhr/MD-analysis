# Estructura de la espiga: https://www.charmm-gui.org/?doc=archive&lib=covid19
### gmx para trabajar local, ${GMX} para trabajar en biofisikx
### D21J es Delta 21 J y PV es la Primer Variante

#GMX=/share/apps/gmx
#GMX=/home/trippm/gromacs-5.1.4/build/bin/gmx
#GMX=/home/trippm/gromacs-2018.2/build_static/bin/gmx
GMX=gmx
PROT='Delta_inter' 
VAR='inter_sm'
### limpiar moleculas de agua, y glicosilaciones (chimera)
#grep -v HOH ${VAR}.pdb > ${PROT}.pdb

### Seleccionar... OPLS-AA/L all-atom force field (2001 aminoacid dihedrals) [opción 15]
#echo 15 | ${GMX} pdb2gmx -f ${PROT}.pdb -o ${PROT}_proccessed.gro -water spce -ignh

###Solvatación [definir caja] #Seleccionar 1:proteina
#echo 1 | ${GMX} editconf -f ${PROT}_proccessed.gro -o ${PROT}_newbox_prev.gro -c -princ -bt triclinic -d 2 
#echo 1 | ${GMX} editconf -f ${PROT}_newbox_prev.gro -o ${PROT}_newbox.gro -translate 7 -0.5 0.8
### Solvatar
#${GMX} solvate -cp ${PROT}_newbox.gro -cs spc216.gro -o ${PROT}_solv.gro -p topol.top
### añadir iones [generar ions.tpr]
#${GMX} grompp -f ions.mdp -c ${PROT}_solv.gro -p topol.top -o ions.tpr

### añadir iones
## seleccionar grupo 13.. modificar los iones en el solvente
#echo 13 | ${GMX} genion -s ions.tpr -o ${PROT}_solv_ions.gro -p topol.top -conc 0.1 -pname NA -nname CL -neutral

### minimización
#${GMX} grompp -f minim.mdp -c ${PROT}_solv_ions.gro -p topol.top -o em.tpr
#nohup ${GMX} mdrun -v -deffnm em &

### seleccionar grupo 10 0... para graficar el potencial
### Visualizar grafica del potenciall
#echo 10 0 | ${GMX} energy -f em.edr -o potential.xvg
#xmgrace potential.xvg

### Equilibración NVT
#${GMX} grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -o nvt.tpr
#${GMX} mdrun -v -deffnm nvt &
### -cpi state.cpt para reiniciar desde donde se quedó
#${GMX} mdrun -v -deffnm nvt -cpi nvt_prev.cpt
### generar grafico xvg de la temperature y observarlo en xmgrace
### seleccionar line 16 0
#echo 16 0 | ${GMX} energy -f nvt.edr -o temperature.xvg
#xmgrace temperature.xvg #ejecutar en computadora local luego de transferir el archivo del servidor

### Equilibración NPT , seleccionar 18 0 para el gŕafico de presión y 24 0 para el de densidad
#${GMX} grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o npt.tpr
#${GMX} mdrun -v -deffnm npt &
#${GMX} mdrun -v -deffnm npt -cpi npt_prev.cpt &
#echo 18 0 | ${GMX} energy -f npt.edr -o pressure.xvg
#echo 24 0 | ${GMX} energy -f npt.edr -o density.xvg

### Producción md | 10 ns
#${GMX} grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -o md_0_1.tpr -maxwarn 2 &
#${GMX} mdrun -v -deffnm md_0_1 &
#${GMX} mdrun -v -deffnm md_0_1 -nb gpu &

## extender MD | 5 ns
#${GMX} convert-tpr -s md_0_1.tpr -extend 5000 -o md_1_2.tpr
#nohup ${GMX} mdrun -v -deffnm md_1_2 -cpi md_0_1.cpt -noappend &

## extender MD | 5 ns
#${GMX} convert-tpr -s md_1_2.tpr -extend 5000 -o md_1_3.tpr
#nohup ${GMX} mdrun -v -deffnm md_1_3 -cpi md_1_2.cpt -noappend &

## extender MD | 10 ns | reanudar 26/01/22
#${GMX} convert-tpr -s md_1_3.tpr -extend 10000 -o md_1_4.tpr
#nohup ${GMX} mdrun -v -deffnm md_1_4 -cpi md_1_4.cpt -noappend &

## unir trayectorias
V='inter'
#${GMX} trjcat -f md_0_1.xtc md_1_2.part0002.xtc md_1_3.part0003 md_1_4.part0004 md_1_4.part0005 md_1_4.part0006.xtc -o md_${V}_30ns.xtc
## remover iones y agua 
#echo 1 1 | ${GMX} trjconv -s md_1_4.tpr -f md_${V}_30ns.xtc -o md_${V}_30ns_noh2o.xtc -pbc nojump -center

### hacer un index donde esten los atomos de cada rbd
#${GMX} make_ndx -f md_0_1.tpr -o ${V}_rbd.ndx
### extraer rbd cadena A: index 19
#CHN='A' ## cadena A, RBD: atomo 5011 al 8500 = 3490 atomos
#echo 19 19 | ${GMX} trjconv -s md_0_1.tpr -f md_${V}_30ns_noh2o.xtc -n ${V}_rbd.ndx -o ${V}_chain${CHN}.pdb -dump 0 -center -pbc mol -ur compact
#echo 19 19 | ${GMX} trjconv -s md_1_4.tpr -f md_${V}_30ns_noh2o.xtc -n ${V}_rbd.ndx -o ${V}_rbd_chain${CHN}.xtc -center -pbc mol -ur compact
#echo 19 | ${GMX} convert-tpr -s md_0_1.tpr -n ${V}_rbd.ndx -o rbd_${CHN}.tpr
#echo 4 4 | ${GMX} rms -s rbd_${CHN}.tpr -f ${V}_rbd_chain${CHN}.xtc -o rmsd_rbd_${V}_chain${CHN}.xvg -tu ns
### extraer rbd cadena B: index 20
#CHN='B' ## cadena B, RBD: atomo 24654 al 28143 = 3490 atomos
#echo 20 20 | ${GMX} trjconv -s md_0_1.tpr -f md_${V}_30ns_noh2o.xtc -n ${V}_rbd.ndx -o ${V}_chain${CHN}.pdb -dump 0 -center -pbc mol -ur compact
#echo 20 20 | ${GMX} trjconv -s md_1_4.tpr -f md_${V}_30ns_noh2o.xtc -n ${V}_rbd.ndx -o ${V}_rbd_chain${CHN}.xtc -center -pbc mol -ur compact
#echo 20 | ${GMX} convert-tpr -s md_0_1.tpr -n ${V}_rbd.ndx -o rbd_${CHN}.tpr
#echo 4 4 | ${GMX} rms -s rbd_${CHN}.tpr -f ${V}_rbd_chain${CHN}.xtc -o rmsd_rbd_${V}_chain${CHN}.xvg -tu ns
### extraer rbd cadena C: index 21
#CHN='C' ## cadena C, RBD: atomo 44297 al 47796 = 3490 atomos
#echo 21 21 | ${GMX} trjconv -s md_0_1.tpr -f md_${V}_30ns_noh2o.xtc -n ${V}_rbd.ndx -o ${V}_chain${CHN}.pdb -dump 0 -center -pbc mol -ur compact
#echo 21 21 | ${GMX} trjconv -s md_1_4.tpr -f md_${V}_30ns_noh2o.xtc -n ${V}_rbd.ndx -o ${V}_rbd_chain${CHN}.xtc -center -pbc mol -ur compact
#echo 21 | ${GMX} convert-tpr -s md_0_1.tpr -n ${V}_rbd.ndx -o rbd_${CHN}.tpr
#echo 4 4 | ${GMX} rms -s rbd_${CHN}.tpr -f ${V}_rbd_chain${CHN}.xtc -o rmsd_rbd_${V}_chain${CHN}.xvg -tu ns


### análisis de cluster
#CHN='A'
#CHN='B'
CHN='C'
#declare -a CUTOFF=("0.1" "0.11" "0.120" "0.130" "0.140" "0.15")
declare -a CUTOFF=("0.11")
 
for val in ${CUTOFF[@]}; do
        echo 4 1 | ${GMX} cluster -s ${V}_chain${CHN}.pdb -f ${V}_rbd_chain${CHN}.xtc -o cluster_${V}${CHN}_rbd_${val}.xpm -g cluster_${V}${CHN}_rbd_${val}.log -dist cluster_${V}${CHN}_rbd_dist_${val}.xvg -sz cluster_${V}${CHN}_rbd_sz_${val}.xvg -clid cluster_${V}${CHN}_rbd_id_${val}.xvg -xvg none -cl cluster${V}${CHN}_avg_${val}.pdb -method gromos -b 0 -om cluster${V}${CHN}_raw_${val}.xpm -cutoff ${val}
done



# muestre  | 20,22 dic
TM='sam8'

#${GMX} trjcat -f md_0_1.xtc md_1_2.part0002.xtc -o md_${TM}.xtc -settime
#echo 1 | ${GMX} editconf -ndef -f npt.gro -o md_${TM}_inter_noh2o.gro
#echo 1 1 | ${GMX} trjconv -s md_0_1.tpr -f md_1_2.part0002.xtc -o md_${TM}_inter_noh2o.xtc -pbc nojump -center
#echo 4 4 | ${GMX} rms -s md_0_1.tpr -f md_${TM}_inter_noh2o.xtc -o rmsd_${TM}_inter.xvg -tu ns
#echo 4 4 | ${GMX} rms -s md_0_1.tpr -f md_${TM}_inter_noh2o.xtc -o rmsd_${TM}_inter.xvg -tu ns






