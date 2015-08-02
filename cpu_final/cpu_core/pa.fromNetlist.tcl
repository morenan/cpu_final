
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name cpu_core -dir "C:/Users/nancy/Xilinx/workspace/cpu_final/cpu_core/planAhead_run_3" -part xc6slx100fgg676-3
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/nancy/Xilinx/workspace/cpu_final/cpu_core/cpu_core.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/nancy/Xilinx/workspace/cpu_final/cpu_core} }
set_property target_constrs_file "C:/Users/nancy/Xilinx/workspace/cpu_final/cpu_core.ucf" [current_fileset -constrset]
add_files [list {C:/Users/nancy/Xilinx/workspace/cpu_final/cpu_core.ucf}] -fileset [get_property constrset [current_run]]
link_design
