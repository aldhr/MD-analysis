# Estructura de la espiga: https://www.charmm-gui.org/?doc=archive&lib=covid19


### gmx para trabajar local, ${GMX} para trabajar en biofisikx
### D21J es Delta 21 J y PV es la Primer Variante

#GMX=/share/apps/gmx
#GMX=/home/trippm/gromacs-5.1.4/build/bin/gmx
#GMX=/home/trippm/gromacs-2018.2/build_static/bin/gmx
GMX=/usr/local/gromacs/bin/gmx
#GMX=gmx


#PROT='orig 
#VAR='original'
### limpiar moleculas de agua, y glicosilaciones (chimera)
#grep -v HOH ${VAR}.pdb > ${PROT}.pdb

### Seleccionar... OPLS-AA/L all-atom force field (2001 aminoacid dihedrals) [opción 15]
#echo 15 | ${GMX} pdb2gmx -f ${PROT}.pdb -o ${PROT}_proccessed.gro -water spce -ignh

### Definir caja #Seleccionar 1:proteina
#echo 1 | ${GMX} editconf -f ${PROT}_proccessed.gro -o ${PROT}_newbox_prev.gro -c -princ -bt triclinic -d 2 
#echo 1 | ${GMX} editconf -f ${PROT}_newbox_prev.gro -o ${PROT}_newbox.gro -translate 7 -0.5 0.8

### Solvatar
#${GMX} solvate -cp ${PROT}_newbox.gro -cs spc216.gro -o ${PROT}_solv.gro -p topol.top

### Generar ions.tpr
#${GMX} grompp -f ions.mdp -c ${PROT}_solv.gro -p topol.top -o ions.tpr

### añadir iones
## seleccionar grupo 13.. modificar los iones en el solvente
#echo 13 | ${GMX} genion -s ions.tpr -o ${PROT}_solv_ions.gro -p topol.top -conc 0.1 -pname NA -nname CL -neutral

### minimización
#${GMX} grompp -f minim.mdp -c ${PROT}_solv_ions.gro -p topol.top -o em.tpr
#nohup ${GMX} mdrun -v -deffnm em &

### Visualizar grafica del potencial
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

### Equilibración NPT
#${GMX} grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o npt.tpr
#${GMX} mdrun -v -deffnm npt &
#${GMX} mdrun -v -deffnm npt -cpi npt_prev.cpt &
#echo 18 0 | ${GMX} energy -f npt.edr -o pressure.xvg
#echo 24 0 | ${GMX} energy -f npt.edr -o density.xvg

##### produccion de dinamica molecular 
### producción MD | 10 ns
#${GMX} grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -o md_0_1.tpr -maxwarn 2 &
#${GMX} mdrun -v -deffnm md_0_1 &
#${GMX} mdrun -v -deffnm md_0_1 -nb gpu &

### extender MD | 5 ns
#${GMX} convert-tpr -s md_0_1.tpr -extend 5000 -o md_1_2.tpr
#nohup ${GMX} mdrun -v -deffnm md_1_2 -cpi md_0_1.cpt -noappend &

### extender MD | 5 ns
#${GMX} convert-tpr -s md_1_2.tpr -extend 5000 -o md_1_3.tpr
#nohup ${GMX} mdrun -v -deffnm md_1_3 -cpi md_1_2.cpt -noappend &

### extender MD | 10 ns  
#${GMX} convert-tpr -s md_1_3.tpr -extend 10000 -o md_1_4.tpr
#nohup ${GMX} mdrun -v -deffnm md_1_4 -cpi md_1_4.cpt -noappend &

###### Anàlisis de trayectorias 

V='Orig'

### Concatenar xtc
#${GMX} trjcat -f md_020.xtc md_040.part0002.xtc md_060.part0003.xtc md_080.part0004.xtc md_100.part0005.xtc -o md_${V}_100ns.xtc

### Remover ions y agua 
#echo 1 1 | ${GMX} trjconv -s md_100.tpr -f md_${V}_100ns.xtc -o md_${V}_100ns_noh2o.xtc -pbc nojump -center
#echo 1 1 | ${GMX} trjconv -s md_020.tpr -f md_020.gro -o md_${V}_noh2o.gro -pbc nojump -center

### Rmsd [Homotrimero completo]
#echo 4 4 | ${GMX} rms -s md_020.tpr -f md_${V}_100ns_noh2o.xtc -o rmsd_${V}_100ns.xvg -tu ns

### Extraer RBD | hacer un index.ndx para cada cadena
#${GMX} make_ndx -f md_020.tpr -o ${V}_rbd.ndx

   ## index 
   ## | CHN | NDX | atoms [3511]  | Notes                                           |
   ## |*****|*****|***************|*************************************************|
   ## |  A  | 19  | 5014  - 8524  | si CHN 'A' es seleccionada, NDX debe ser 19,    |
   ## |  B  | 20  | 24688 - 28198 | mientras el NDX, cuando CHN='B' es seleccionada |
   ## |  C  | 21  | 44361 - 47871 | es 20, y en el caso de CHN='C', NDX es 21       |

###Crear archivos pdb, xtc, tpr y rms de cada cadena RBD
CHN='C' 
NDX=21                                                                                                                                                         ##file:
#echo ${NDX} ${NDX} | ${GMX} trjconv -s md_020.tpr -f md_${V}_100ns_noh2o.xtc -n ${V}_rbd.ndx -o ${V}_chain${CHN}.pdb -dump 0 -center -pbc mol -ur compact      ##pdb
#echo ${NDX} ${NDX} | ${GMX} trjconv -s md_100.tpr -f md_${V}_100ns_noh2o.xtc -n ${V}_rbd.ndx -o ${V}_rbd_chain${CHN}.xtc -center -pbc mol -ur compact          ##xtc
#echo ${NDX} | ${GMX} convert-tpr -s md_020.tpr -n ${V}_rbd.ndx -o rbd_${CHN}.tpr                                                                               ##tpr
#echo 4 4 | ${GMX} rms -s rbd_${CHN}.tpr -f ${V}_rbd_chain${CHN}.xtc -o rmsd_rbd_${V}_chain${CHN}.xvg -tu ns                                                    ##rms 
#xmgrace rmsd_rbd_${V}_chain${CHN}.xvg 
##### Concatenar trayectorias: opcion 1 
#${GMX} trjcat -f ${V}_rbd_chainA.xtc ${V}_rbd_chainB.xtc ${V}_rbd_chainC.xtc -o md_${V}_3rbds_300ns_noh2o.xtc -settime
#echo 4 4 | ${GMX} rms -s rbd_A.tpr -f md_${V}_3rbds_300ns_noh2o.xtc -o rmsd_md_${V}_3rbds_300ns_noh2o.xvg -tu ns
#xmgrace rmsd_md_${V}_3rbds_300ns_noh2o.xvg


##### Concatenar trayectorias: opcion 2
### Alinear RBDs respecto a la cadena A y luego concatenar con los archivos correspondientes
## Archivos Cadena A [generados en el paso previo, cambio de nombre por consistencia de trabajo]
#cp ${V}_chainA.pdb ${V}_chainA_fit.pdb
#cp ${V}_rbd_chainA.xtc ${V}_rbd_chainA_fit.xtc
## Archivos Cadena B 
#echo 1 1 | ${GMX} confrms -f1 ${V}_chainA.pdb -f2 ${V}_chainB.pdb -o ${V}_chainB_fit.pdb -one
#echo 1 1 | ${GMX} trjconv -f ${V}_rbd_chainB.xtc -s ${V}_chainB_fit.pdb -o ${V}_rbd_chainB_fit.xtc -fit rot+trans
## Archivos Cadena C
#echo 1 1 | ${GMX} confrms -f1 ${V}_chainA.pdb -f2 ${V}_chainC.pdb -o ${V}_chainC_fit.pdb -one
#echo 1 1 | ${GMX} trjconv -f ${V}_rbd_chainC.xtc -s ${V}_chainC_fit.pdb -o ${V}_rbd_chainC_fit.xtc -fit rot+trans
### trjcat
#${GMX} trjcat -f ${V}_rbd_chainA_fit.xtc ${V}_rbd_chainB_fit.xtc ${V}_rbd_chainC_fit.xtc -o md_${V}_3rbds_300ns_noh2o_fit.xtc -settime
#echo 4 4 | ${GMX} rms -s rbd_A.tpr -f md_${V}_3rbds_300ns_noh2o_fit.xtc -o rmsd_md_${V}_3rbds_300ns_noh2o_fit.xvg -tu ns
#xmgrace rmsd_md_${V}_3rbds_300ns_noh2o_fit.xvg


##### Concatenar trayectorias: opcion 3 
## Archivos Cadena A [generados en el paso previo, cambio de nombre por consistencia de trabajo]
#cp ${V}_chainA.pdb ${V}_chainA_fit_toA.pdb
#cp ${V}_rbd_chainA.xtc ${V}_rbd_chainA_fit_toA.xtc
## Archivos Cadena B 
#echo 1 1 | ${GMX} confrms -f1 ${V}_chainA.pdb -f2 ${V}_chainB.pdb -o ${V}_chainB_fit.pdb -one
#echo 1 1 | ${GMX} trjconv -f ${V}_rbd_chainB.xtc -s ${V}_chainA_fit.pdb -o ${V}_rbd_chainB_fit_toA.xtc -fit rot+trans
## Archivos Cadena C
#echo 1 1 | ${GMX} confrms -f1 ${V}_chainA.pdb -f2 ${V}_chainC.pdb -o ${V}_chainC_fit.pdb -one
#echo 1 1 | ${GMX} trjconv -f ${V}_rbd_chainC.xtc -s ${V}_chainA_fit.pdb -o ${V}_rbd_chainC_fit_toA.xtc -fit rot+trans
### trjcat
#${GMX} trjcat -f ${V}_rbd_chainA_fit_toA.xtc ${V}_rbd_chainB_fit_toA.xtc ${V}_rbd_chainC_fit_toA.xtc -o md_${V}_3rbds_300ns_noh2o_fit_toA.xtc -settime
#echo 4 4 | ${GMX} rms -s rbd_A.tpr -f md_${V}_3rbds_300ns_noh2o_fit_toA.xtc -o rmsd_md_${V}_3rbds_300ns_noh2o_fit_toA.xvg -tu ns
#echo 4 4 | ${GMX} rms -s rbd_A.tpr -f md_${V}_3rbds_300ns_noh2o_fit_toA.xtc -o ejemplooo_rmsd_md_${V}_3rbds_300ns_noh2o_fit_toA.xvg -tu ns
#xmgrace rmsd_md_${V}_3rbds_300ns_noh2o_fit_toA.xvg

##### Anàlisis de cluster 
#declare -a CUTOFF=("0.05" "0.10" "0.11" "0.12" "0.13" "0.14" "0.15" "0.16" "0.17" "0.18" "0.19" "0.20" "0.21" "0.22" "0.23" "0.24" "0.25" "0.26" "0.27" "0.28" "0.29" "0.30" "0.31" "0.32" "0.33" "0.35" "0.36" "0.37" "0.38" "0.39" "0.40")
#for val in ${CUTOFF[@]}; do
#        echo 4 1 | ${GMX} cluster -s ${V}_chainA.pdb -f md_${V}_3rbds_300ns_noh2o_fit.xtc -o cluster_${V}_rbd_${val}.xpm -g cluster_${V}_rbd_${val}.log -dist cluster_${V}_rbd_dist_${val}.xvg -sz cluster_${V}_rbd_sz_${val}.xvg -clid cluster_${V}_rbd_id_${val}.xvg -ev exmaple.xvg -xvg none -cl centroide_${V}_${val}.pdb -method gromos -b 0 -om cluster${V}_raw_${val}.xpm -cutoff ${val}
#	mv cluster* centroide* xcluster_files
#done

##xpm2ps
#cutoff="0.21"
#${GMX} xpm2ps -f xcluster_files/cluster_Orig_rbd_${cutoff}.xpm -o rms_matrix_${cutoff}.eps -rainbow red

##rmsf del RBD
${GMX} rmsf -f md_${V}_3rbds_300ns_noh2o_fit.xtc -s rbd_A.tpr -o rmsf_rbd_${V}.xvg -res

