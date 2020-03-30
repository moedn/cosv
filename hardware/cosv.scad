//COSV - Cam Open Source Ventilator
// Project home: https://hackaday.io/project/170507
// Project files: https://github.com/Arcus-3d/cosv
// Project author: Daren Schwenke

// circle complexity.  Turn down for working, up to like 60 for rendering
$fn=30;

// Assembly views, currently broken.
//assembly_view(cam_angle=$t*180,explode=0);
//cam_assembly(explode=10);

// uncomment these to generate them, render, export.
// for the laser files, export as svg.

//cam();
//arm_l();
//paddle();
//base_b();
//base_t();
//chest_bar();
//bag_mount();
//bearing_bushing();
//bearing_washer();
if (0) projection() translate([0,0,-15.5]) rotate([90,0,0]) intersection() {
	union() {
		flow_sensor_for_pcb();
		cube([10,100,10],center=true);
	}
	translate([0,15.55,0]) cube([1000,0.1,1000],center=true);
}
flow_sensor_for_pcb();
//flow_sensor_cover(oled=1);
//flow_sensor_cover();
//bldc_motor_standoff();

//laser_callibration_square(w=10);
//laser_arm_mount();
//laser_bearing_washer();
//laser_cam();
//laser_bearing_bushing();
//laser_cam_center();
//laser_bldc_motor_standoff();
//laser_base_t();
//laser_base_b();
//laser_paddle();
//laser_arm();

// generates the path for the cam.
path_step=2; // turn down when rendering the actual path for a smooth one... up to 10 when editing.

//assembly_view(cam_angle=$t*180,explode=0);
//cam_assembly(explode=10);


clearance=0.4;
extra=0.02;
// nozzle size for 3D printing.  Generates parts that are exactly a multiple of this width for strength
nozzle_r=0.4/2;

// line width for laser cutting.  Affects hole sizes
kerf=0;
//kerf=0.025;

// bag dimensions and position
bvm_r=125/2;
bvm_br=70/2;
bvm_tr=45/2;
bvm_l=200;
bvm_c=nozzle_r*2*8;
bvm_y_offset=15;

//
chest_bar_l=bvm_r*2;
// bearing choice.  Some things don't scale right yet if you change this.
bearing_or=22/2-kerf;
bearing_ir=8/2+kerf;
bearing_h=7;
// a little washer to clearance the bearing
bearing_washer_h=clearance/2;

// assembly bolt size
bolt_r=3/2+clearance/4-kerf;

// compression rotation angle.  You can generate uneven compression/release profiles with this for a weaker motor, or to have hardware ratio of inhale/exhale and a static motor.
comp_rot=90;

// arm width
arm_w=10*nozzle_r*2;

// paddle internal ribs and top thickness
paddle_scale=1.5;
paddle_t=3*nozzle_r*2;
paddle_rib_w=3*nozzle_r*2;

// how far the arm rotates with a full comp_rot
arm_rot=30; 
// how far apart the arm bearings are from centerline
arm_x_offset=16;

// mechanical dimensions for the cam action
cam_bearing_offset=15+nozzle_r*2;
cam_l=cam_bearing_offset*2+bearing_or*2;
cam_thickness=2;
cam_h=bearing_h+cam_thickness*2+clearance;
cam_y_offset=bearing_or+cam_l/2;
cam_pre_rot=-0;
x_pos=arm_x_offset+cam_l/2.5;
y_pos=-cam_y_offset-cam_l/2.5;


// volume sensing pitot tube dimensions
// outer tube.  This is the dia of the mask, generally
tube_or=22/2-nozzle_r;
tube_taper=nozzle_r;
tube_ir=tube_or-nozzle_r*2*5;

pcb_t=1.6+3.2+clearance; // OLED is 5.2mm tall.  Recess in lid is 2mm.
pcb_c_t=2.4;
pcb_b=1.6;
pcb_x=16+clearance;
pcb_y=43+clearance;
pcb_z_offset=4;
pcb_port_z_offset=8;
pcb_port_z_spacing=4;
pcb_port_x_spacing=4;
pcb_bolt_spacing=24;
pcb_cover_t=2.8;
pcb_cable_t=1.5;
// depth of the socket/tube
tube_d=20;
// total length
tube_l=tube_d*2+(pcb_y-tube_d)+pcb_z_offset+16;
// inner pitot tube
pitot_r=4.2/2;
pitot_t=nozzle_r*2*2;
port_r=5.25/2;
oled_x=12+clearance;
oled_y=39+clearance;
oled_t=2;
oled_glass_x=11;
oled_glass_y=30;

//t=tube_or-tube_ir;
//translate([0,-tube_l/2-tube_d/1.5,tube_or+t+pcb_t+pcb_c_t+pcb_cover_t/2+pcb_b]) rotate([-90,0,0]) flow_sensor_cover(oled=0);


module flow_sensor_cover(oled=0) {
	t=tube_or-tube_ir;
	if (1) difference() {
		union() {
			hull() for (x=[-1,1]) for (z=[-1,1]) translate([(pcb_x+pcb_b)/2*x,tube_or+t+pcb_t+pcb_c_t+extra/2,tube_l-(pcb_y+pcb_b*2)/2-pcb_z_offset+(pcb_y+pcb_b+pcb_z_offset*2)/2*z]) {
				rotate([90,0,0]) cylinder(r=pcb_b/2,h=extra,center=true);
				translate([x*-0.5,pcb_cover_t-pcb_b/2,0]) sphere(r=pcb_b/2,center=true);
			}
			difference() {
				hull() {
					translate([0,tube_or+t+pcb_cover_t/2+pcb_t+pcb_c_t,tube_l-pcb_z_offset/2]) translate([0,-pcb_t+t/2,0]) cube([pcb_x/3,pcb_c_t,pcb_z_offset+extra],center=true);
					translate([0,tube_or+t+pcb_t+pcb_c_t+extra/2,tube_l-pcb_z_offset/2]) cube([pcb_x/3,extra,pcb_z_offset+extra],center=true);
				}
				translate([0,tube_or+t+pcb_cover_t/2+pcb_t+pcb_c_t,tube_l-pcb_z_offset/2]) translate([0,-pcb_t/2-pcb_c_t/2-pcb_cover_t/2,-t/2]) rotate([0,90,0]) cylinder(r=t/1.5,h=pcb_x/3+extra,center=true);
			}
			translate([0,tube_or+t+pcb_t+pcb_c_t,tube_l-(pcb_y+pcb_b*2)-pcb_z_offset+pcb_b/2]) hull() {
				cube([pcb_x,extra,pcb_b*2.5-clearance/3],center=true);
				rotate([45,0,0]) translate([0,-pcb_b*2,0]) rotate([0,90,0]) cylinder(r=pcb_b/2,h=pcb_x,center=true);
			}
			translate([0,tube_or+t+pcb_t+pcb_c_t,tube_l-(pcb_y+pcb_b)/2-pcb_z_offset]) cube([oled_x+pcb_b*2,oled_t+extra,oled_y+pcb_b*2],center=true);
		}
		translate([0,tube_or+t+pcb_t+pcb_c_t+oled_t/2-pcb_b,tube_l-(pcb_y+pcb_b)/2-pcb_z_offset]) cube([oled_x+clearance,oled_t+pcb_b*2+extra,oled_y+clearance],center=true);
		if (oled) translate([0,tube_or+t+pcb_t+pcb_c_t+oled_t/2-pcb_b,tube_l-(pcb_y+pcb_b)/2-pcb_z_offset]) cube([oled_glass_x,oled_t*2+pcb_b*2+extra,oled_glass_y],center=true);
		for (x=[-1,1]) for (z=[1]) translate([(pcb_x+pcb_b-t*3)/2*x,tube_or+t*2.8+pcb_cover_t+extra/2,tube_l-(pcb_y+pcb_b*2)/2-pcb_z_offset+(pcb_y+pcb_b+pcb_z_offset*2-t*2.5)/2*z]) {
			rotate([90,0,0]) cylinder(r=3/2,h=pcb_t+pcb_c_t+t,center=true);
			translate([0,pcb_cover_t,0]) rotate([90,0,0]) cylinder(r1=3/2,r1=3,h=3,center=true);
		}
		//translate([0,tube_or+t+pcb_t+pcb_c_t+oled_t/2-pcb_b,tube_l-(pcb_y+pcb_b)/2-pcb_z_offset]) cube([oled_x+clearance,oled_t+pcb_b*2+extra,oled_y+clearance],center=true);
	}
}

// holes still don't scale for depth correctly.
module flow_sensor_for_pcb() {
	t=tube_or-tube_ir;
	difference() {
		if (1) union() {
			// bottom taper
			translate([0,0,tube_d/2+t/4]) cylinder(r2=tube_or+tube_taper,r1=tube_or,h=tube_d-t/2,center=true);
			translate([0,0,t/4]) cylinder(r1=tube_or-t/4,r2=tube_or,h=t/2,center=true);
			// top
			hull() {
				for (z=[0,-pcb_y-pcb_b-pcb_z_offset*2]) translate([0,0,tube_l-t/2+z]) rotate_extrude() translate([tube_or+t-t/2,0]) circle(r=t/2,center=true);
				//translate([0,0,tube_l-(pcb_y+pcb_b*2)/2-pcb_z_offset]) cylinder(r=tube_or+t,h=pcb_y+pcb_b*2+pcb_z_offset*2,center=true);
				for (x=[-1,1]) for (z=[-1,1]) translate([(pcb_x+pcb_b)/2*x,tube_or+t+pcb_t/2+pcb_c_t/2,tube_l-(pcb_y+pcb_b*2)/2-pcb_z_offset+(pcb_y+pcb_b+pcb_z_offset*2)/2*z]) rotate([90,0,0]) cylinder(r=pcb_b/2,h=pcb_t+pcb_c_t,center=true);
// cube([pcb_x+pcb_b*2,pcb_t+pcb_c_t,pcb_y+pcb_b*2+pcb_z_offset*2],center=true);
				translate([0,0,tube_l/2]) cylinder(r=tube_or+tube_taper,h=tube_l-tube_d*2,center=true);
			}
		}
		difference() {
			if (1) union() {
				// screw holes
				for (x=[-1,1]) for (z=[1]) translate([(pcb_x+pcb_b-t*3)/2*x,tube_or+t*3+extra/2,tube_l-(pcb_y+pcb_b*2)/2-pcb_z_offset+(pcb_y+pcb_b+pcb_z_offset*2-t*2.5)/2*z]) rotate([90,0,0]) cylinder(r=3/2-clearance,h=pcb_t+pcb_c_t+t+t,center=true);
				// led hole/vent
				translate([0,tube_or+t/2+pcb_t/2+pcb_c_t/2,tube_l-pcb_b*2-t-pcb_z_offset]) scale([1,0.5,1.25]) rotate([0,90,0]) cylinder(r=t,h=pcb_x*2,center=true);
				// center cutout
				translate([0,0,tube_l/2]) cylinder(r=tube_ir,h=tube_l+extra*2,center=true);
				// top taper lip
				translate([0,0,tube_l]) cylinder(r1=tube_or,r2=tube_or+t/2,h=t,center=true);
				// top taper cutout
				translate([0,0,tube_l-tube_d/2]) cylinder(r2=tube_or,r1=tube_or-tube_taper,h=tube_d+extra,center=true);
				// cover mount cutout
				translate([0,tube_or+t+pcb_t+pcb_c_t,tube_l-(pcb_y+pcb_b*2)-pcb_z_offset+pcb_b/2]) hull() {
					cube([pcb_x,extra,pcb_b*2.5],center=true);
					rotate([45,0,0]) translate([0,-pcb_b*2,0]) rotate([0,90,0]) cylinder(r=pcb_b/2,h=pcb_x,center=true);
				}
				// cable_crimp_cutout
				translate([0,tube_or+t+pcb_cover_t/2+pcb_t+pcb_c_t/2,tube_l-pcb_z_offset/2]) difference() {
					cube([pcb_x/3,pcb_t+pcb_c_t+pcb_cover_t,pcb_z_offset+extra],center=true);
					translate([0,-pcb_t/2-pcb_c_t/2-pcb_cover_t/2,-t/2]) rotate([0,90,0]) cylinder(r=t/3,h=pcb_x/3,center=true);
				}
				// pcb_pocket
				difference() {
					union() {
						translate([0,tube_or+t+pcb_t/2+pcb_c_t/2,tube_l-(pcb_y+pcb_b-pcb_port_z_offset)/2]) cube([pcb_x,pcb_t+pcb_c_t+extra,pcb_y+pcb_b-pcb_port_z_offset*2+extra],center=true);
						translate([0,tube_or+t+pcb_t/2+pcb_c_t,tube_l-(pcb_y+pcb_b)/2-pcb_z_offset]) cube([pcb_x,pcb_t+extra,pcb_y+pcb_b+extra],center=true);
					}
					difference() {
						translate([0,tube_or+t+pcb_t/2+pcb_c_t/2,tube_l-pcb_b]) rotate([-45,0,0]) cube([pcb_x,pcb_t+pcb_c_t+extra,pcb_y+pcb_b-pcb_port_z_offset*2+extra],center=true);
						translate([0,tube_or+t+pcb_cover_t/2+pcb_t+pcb_c_t/2,tube_l-pcb_z_offset/2]) cube([pcb_x/3,pcb_t+pcb_c_t+pcb_cover_t,pcb_z_offset*2+extra],center=true);
					}
				}
				// lower screw hole
				for (z=[0]) translate([0,tube_or+pcb_c_t,tube_l-pcb_y-pcb_b+pcb_port_z_offset+z*pcb_port_z_spacing-pcb_z_offset]) rotate([90,0,0]) cylinder(r=bolt_r-clearance/2,h=t*3.75,center=true);
				// pitot pcb ports
				// relative surface height of the top of the ports
				o=tube_or+t+pcb_c_t;
				i=-pcb_c_t-t*3;
				// ports
				for (x=[-1,1]) translate([x*pcb_port_x_spacing,o,tube_l-pcb_y-pcb_b+pcb_port_z_offset-pcb_port_z_spacing-pcb_z_offset]) hull() {
					translate([0,-pcb_c_t/2,port_r]) rotate([90,0,0]) cylinder(r=port_r/8,h=pcb_c_t,center=true);
					translate([0,-pcb_c_t/2,-port_r/6]) rotate([90,0,0]) cylinder(r=port_r,h=pcb_c_t,center=true);
					translate([0,i,port_r/3]) rotate([90,0,0]) cylinder(r=port_r/8,h=extra,center=true);
					translate([0,i,-port_r/8]) rotate([90,0,0]) cylinder(r=port_r/2,h=extra,center=true);
				}
				for (x=[-1]) translate([x*pcb_port_x_spacing,o,tube_l-pcb_y-pcb_b+pcb_port_z_offset+pcb_port_z_spacing-pcb_z_offset]) hull() {
					translate([0,-pcb_c_t/2,port_r]) rotate([90,0,0]) cylinder(r=port_r/8,h=pcb_c_t,center=true);
					translate([0,-pcb_c_t/2,-port_r/6]) rotate([90,0,0]) cylinder(r=port_r,h=pcb_c_t,center=true);
					translate([0,i,port_r/3]) rotate([90,0,0]) cylinder(r=port_r/8,h=extra,center=true);
					translate([0,i,-port_r/8]) rotate([90,0,0]) cylinder(r=port_r/2,h=extra,center=true);
				}
				// absolute pressure port
				hull() for (z=[-port_r/4,port_r*2]) translate([pcb_port_x_spacing,tube_or+t+pcb_c_t/2+pcb_t/2,tube_l-pcb_y-pcb_b+pcb_port_z_offset+pcb_port_z_spacing+z-pcb_z_offset]) rotate([90,0,0]) cylinder(r=port_r,h=pcb_t+t,center=true);
			}
			rotate([0,0,25]) { // if you alter the depth of the ports, this needs to change and I'm too lazy to do that math.
				translate([0,0,tube_l-pcb_y-pcb_b+pcb_port_z_offset-pcb_z_offset]) intersection() {
					union() {
						for (r=[1,0]) mirror([0,0,r]) translate([0,tube_ir,tube_ir+pcb_port_z_spacing]) rotate([0,90,0]) difference() {
							union() {
								rotate_extrude() translate([tube_ir,0]) circle(r=pitot_r+pitot_t,center=true);
								translate([tube_or/2+pcb_port_x_spacing/2,(-tube_or-t)/2,0]) cube([tube_or+pcb_port_x_spacing,tube_or+t+pitot_r+pitot_t-pcb_b,pitot_t*2],center=true);
							}
							rotate_extrude() translate([tube_ir,0]) circle(r=pitot_r,center=true);
						}
					}
					translate([0,(tube_ir+t-pitot_r-pitot_t-pcb_b)/2+clearance/4,0]) cube([tube_ir,tube_ir+t+pitot_r+pitot_t-pcb_b,(tube_ir+pcb_port_z_spacing)*2],center=true);
				}
				if (1) difference() {
					h=tube_l-pcb_y-pcb_b+pcb_port_z_offset-pcb_z_offset-nozzle_r-(tube_ir+pcb_port_z_spacing);
					union() {
						translate([0,0,h/2-pitot_t/2]) cylinder(r=pitot_r+pitot_t*2,h=h-pitot_t,center=true);
						translate([0,0,h-pitot_t/2]) cylinder(r1=pitot_r+pitot_t*2,r2=pitot_r+pitot_t/2,h=pitot_t,center=true);
					}
					translate([0,0,h/2]) cylinder(r=pitot_r,h=h+extra,center=true);
				
					
				}
			}
		}
		if (0) {
			%translate([0,tube_or+t+pcb_t/2+pcb_c_t,tube_l-(pcb_y+pcb_b)/2-pcb_z_offset]) cube([pcb_x-pcb_b,pcb_t+extra,pcb_y-pcb_b+extra],center=true);
			#translate([0,tube_or+t+pcb_t/2+pcb_c_t,tube_l-(pcb_y+pcb_b)/2-pcb_z_offset]) cube([oled_x,pcb_t+extra,oled_y],center=true);
		}
	}
}
module flow_sensor() {
	translate([0,0,tube_l/2]) difference() {
		if (1) union() {
			cylinder(r=tube_or,h=tube_l,center=true);
			rotate([90,0,0]) hull() for (z=[1,-1]) translate([0,z*8,-tube_or/1.5]) cylinder(r=tube_or/2,h=tube_or/1.15,center=true);
		}
		difference() {
			cylinder(r=tube_ir,h=tube_l+extra,center=true);
			for (r=[1,0]) mirror([0,0,r]) scale([1,1,2.1]) translate([0,tube_ir,-tube_l/4.3]) rotate([0,90,0]) intersection() {
				difference() {
					union() {
						translate([0,-pitot_r-pitot_t+clearance/4,0]) cube([tube_l*2/4.3,tube_ir*2,pitot_t],center=true);
						rotate_extrude() translate([tube_ir,0]) circle(r=pitot_r+pitot_t,center=true);
					}
					rotate_extrude() translate([tube_ir,0]) circle(r=pitot_r,center=true);
				}
				cube([tube_l,tube_or*3,tube_ir],center=true);
			}
		}
		for (z=[-1,0,1]) translate([0,tube_ir+4,z*8]) rotate([90,0,0]) translate([0,0,0]) cylinder(r=port_r,h=8*2,center=true);
		
	}
}

////// motor selection

// small worm gear motor
//motor_shaft_r=6/2-kerf;
//motor_mount_y=33;
//motor_mount_x=18;
//motor_mount_offset=9;
//motor_pilot_r=6/2+clearance-kerf;
//motor_bolt_r=3/2+clearance/4-kerf;

// BLDC gear motor
motor_shaft_r=8/2-kerf;
motor_mount_y=26.75;
motor_mount_x=15.5;
motor_mount_offset=6.25;
motor_pilot_r=12/2+clearance-kerf;
motor_bolt_r=3/2+clearance/4-kerf;
motor_body_y_offset=-7;
motor_r=37/2;

// Nema 23
//motor_bolt_r=4/2+clearance/4;
//motor_shaft_r=6.35/2-kerf;
//motor_shaft_r=8/2;
//motor_mount_y=47.1;
//motor_mount_x=47.1;
//motor_mount_offset=47.1/2;
//motor_pilot_r=38.1/2+clearance-kerf;

module laser_base_t() {
	projection(cut=true) base_plate();
}
module laser_bearing_washer() {
	projection(cut=true) bearing_washer();
}
module laser_cam() {
	projection(cut=true) cam_plate();
}
module laser_cam_center() {
	projection(cut=true) cam_center();
}
module laser_arm_mount() {
	projection(cut=true) arm_mount();
}
module laser_arm() {
	arm_model();
	//projection(cut=true) arm_model();
}
module laser_paddle() {
	projection(cut=true) paddle(laser=1);
}
module laser_bearing_bushing() {
	projection(cut=true) bearing_bushing();
}
module laser_base_b() {
	difference() {
		base_plate();
		motor_holes();
	}
}
module laser_callibration_square(w=10) {
	projection(cut=true) cube([w,w,w],center=true);
}
module laser_bldc_motor_standoff() {
	projection(cut=true) bldc_motor_standoff();
}

// now a little screwed up since I split the parts into layers
module assembly_view(explode=0,cam_angle=0) {
	if (1) translate([0,bvm_r+bearing_or+bvm_c+bvm_y_offset,0]) {
	//if (0) {
		//$fn=32;
		if (cam_angle < comp_rot) {
			hull() {
				scale([0.98-cam_angle/100,1,1.5]) sphere(r=bvm_r,center=true);
				translate([0,0,bvm_l/2]) cylinder(r=bvm_tr,h=extra,center=true);
			}
			hull() {
				scale([0.98-cam_angle/100,1,1.5]) sphere(r=bvm_r,center=true);
				translate([0,0,-bvm_l/2]) cylinder(r=bvm_br,h=extra,center=true);
			}
		} else { 
			hull() {
				scale([0.98-(90*2/100-cam_angle/100),1,1.5]) sphere(r=bvm_r,center=true);
				translate([0,0,bvm_l/2]) cylinder(r=bvm_tr,h=extra,center=true);
			}
			hull() {
				scale([0.98-(90*2/100-cam_angle/100),1,1.5]) sphere(r=bvm_r,center=true);
				translate([0,0,-bvm_l/2]) cylinder(r=bvm_br,h=extra,center=true);
			}
		}
	}
	if (0) translate([0,0,-cam_thickness*2-explode*4]) base_b();
	if (1) translate([0,0,-cam_thickness-explode*3]) arm_mount();
	if (1) translate([0,-cam_y_offset,0]) rotate([0,0,-cam_angle+cam_pre_rot]) cam_assembly(explode=0);
	if (0) translate([0,bvm_y_offset+bearing_or/2,explode*5]) rotate([90,0,90]) translate([0,0,-bearing_h/2]) bag_mount();
	if (0) mirror([0,0,1]) translate([0,bvm_y_offset+bearing_or/2,-explode*5]) rotate([90,0,90]) translate([0,0,-bearing_h/2]) bag_mount();
	if (1) translate([arm_x_offset,0,cam_thickness]) {
		translate([0,0,bearing_h/2]) bearing();
		if (cam_angle < comp_rot) {
			rotate([0,0,cam_angle/(comp_rot/arm_rot)]) {
				arm_r();
				if (1) translate([-arm_x_offset+bvm_r,bvm_r+bvm_y_offset+bearing_or+bvm_c,bearing_h/2]) rotate([0,-90,0]) translate([0,0,-bvm_c*2]) rotate([-arm_rot/2,0,0]) paddle();
			}
		} else {
			rotate([0,0,comp_rot/(comp_rot/arm_rot)*2-cam_angle/(comp_rot/arm_rot)]) {
				arm_r();
				if (1) translate([-arm_x_offset+bvm_r,bvm_r+bvm_y_offset+bearing_or+bvm_c,bearing_h/2]) rotate([0,-90,0]) translate([0,0,-bvm_c*2]) rotate([-arm_rot/2,0,0]) paddle();
			}
		}
	}
	if (1) translate([-arm_x_offset,0,cam_thickness]) {
		translate([0,0,bearing_h/2+clearance]) bearing();
		if (cam_angle < comp_rot) {
			rotate([0,0,-cam_angle/(comp_rot/arm_rot)]) {
				arm_l();
				if (1) translate([arm_x_offset-bvm_r,bvm_r+bvm_y_offset+bearing_or+bvm_c,bearing_h/2]) rotate([0,90,0]) translate([0,0,-bvm_c*2]) rotate([-arm_rot/2,0,0]) paddle();
			}
		} else {
			rotate([0,0,-comp_rot/(comp_rot/arm_rot)*2+cam_angle/(comp_rot/arm_rot)]) {
				arm_l();
				if (1) translate([arm_x_offset-bvm_r,bvm_r+bvm_y_offset+bearing_or+bvm_c,bearing_h/2]) rotate([0,90,0]) translate([0,0,-bvm_c*2]) rotate([-arm_rot/2,0,0]) paddle();
			}
		}
	}
}

module bearing_bushing(h=bearing_h,r=bearing_ir-clearance/8) {
	difference() {
		translate([0,0,h/2]) cylinder(r=r,h=h,center=true);
		translate([0,0,h/2]) cylinder(r=bolt_r,h=h+extra,center=true);
	}
}

module bearing_washer(h=bearing_washer_h,ir=bolt_r,or=(bearing_or+bearing_ir)/2) {
	difference() {
		translate([0,0,h/2]) cylinder(r=or,h=h,center=true);
		translate([0,0,h/2]) cylinder(r=ir,h=h+extra,center=true);
	}
}
	
module arm_mount_plate(h=cam_thickness) {
	difference() {
		union() {
			hull() {
				for (x=[-1,1]) translate([x*arm_x_offset,0,h/2]) cylinder(r=bearing_or+bvm_c/4,h=h,center=true);
				hull() for (x=[-1,1]) translate([x*(bearing_h),bvm_y_offset+bearing_or-bvm_c,h/2]) cylinder(r=bvm_c,h=h,center=true);
				for (x=[-1,1]) translate([x*(bearing_h),bvm_y_offset+bearing_or-bvm_c,h/2]) cylinder(r=bvm_c,h=h,center=true);
			}
		}
		for (x=[-1,1]) translate([x*arm_x_offset,0,0]) {
			translate([0,0,h/2]) cylinder(r=bolt_r,h=h+extra,center=true);
		}
		translate([0,bvm_y_offset,h/2]) cube([bearing_h,bearing_h*1.5,h+extra],center=true);
	}
}
module arm_mount(h=cam_thickness) {
	arm_mount_plate(h=h);
}

// not right anymore...
module chest_bar(h=cam_thickness*3+bearing_h+bearing_washer_h*2) {
	difference() {
		union() {
			hull() {
				for (x=[-1,1]) for (y=[1]) translate([x*x_pos,y*(y_pos),h/2]) cylinder(r=bearing_or/2,h=h,center=true);
				for (x=[-1,1]) translate([x*x_pos,y_pos,h/2]) cylinder(r=bearing_or/2-clearance/4,h=h,center=true);
				for (x=[-1,1]) translate([x*x_pos,y_pos,h/2]) cylinder(r=bolt_r+bvm_c,h=h,center=true);
				for (x=[-1,1]) translate([x*chest_bar_l/2,y_pos-bvm_c*2,h/2]) cylinder(r=bvm_c*2,h=h,center=true);
			}
			hull() {
				for (x=[-1,1]) translate([x*(x_pos*1.2),y_pos,h/2]) cylinder(r=bolt_r+bvm_c,h=h,center=true);
				for (x=[-1,1]) translate([x*x_pos,y_pos*0.85,h/2]) cylinder(r=bolt_r+bvm_c,h=h,center=true);
			}
		}
		base_holes(h=h);
	}
}
				
module base_plate(h=cam_thickness,explode=0) {
	difference() {
		union() {
			arm_mount(h=h);
			hull() {
				for (x=[-1,1]) for (y=[0,1]) translate([x*x_pos,y*y_pos,h/2]) cylinder(r=bearing_or/2,h=h,center=true);
				motor_mount(h=h);
			}
			for (x=[-1,1]) hull() {
				translate([x*(arm_x_offset),0,h/2]) cylinder(r=bearing_or,h=h,center=true);
				translate([0,bvm_r+bearing_or+bvm_c+bvm_y_offset,h/2]) rotate([0,0,x*60]) translate([0,-bvm_r-bvm_c*3,0]) cylinder(r=bvm_c,h=h,center=true);
				translate([x*x_pos,0,h/2]) cylinder(r=bearing_or/2,h=h,center=true);
			}
			for (x=[-1,1]) hull() {
				translate([x*(bearing_h),bvm_y_offset+bearing_or-bvm_c,h/2]) cylinder(r=bvm_c,h=h,center=true);
				translate([0,bvm_r+bearing_or+bvm_c+bvm_y_offset,h/2]) rotate([0,0,x*33]) translate([0,-bvm_r-bvm_c*3,0]) cylinder(r=bvm_c,h=h,center=true);
				translate([x*x_pos,0,h/2]) cylinder(r=bearing_or/2,h=h,center=true);
			}
			chest_bar(h=h);
		}
		base_holes(h=h);
	}
		
}

module base_t(h=cam_thickness,explode=0) {
	difference() {
		union() {
			translate([0,0,0]) base_plate(h=h);
			translate([0,0,h+explode]) arm_mount(h=h*2);
			for (x=[-1,1]) translate([arm_x_offset*x,0,0]) {
				translate([0,0,h*3+explode*2]) bearing_washer();
				translate([0,0,h*3+explode*3+bearing_washer_h]) bearing_bushing(h=bearing_h/2);
			}
		}
		translate([0,-cam_y_offset,h/2]) cylinder(r=motor_shaft_r+clearance,h=h+extra,center=true);
	}
}

module base_b(h=cam_thickness) {
	difference() {
		base_t(h=h);
		motor_holes(h=h);
	}
}
module bldc_motor_standoff(h=cam_thickness*2) {
	difference() {
		translate([0,-cam_y_offset-motor_body_y_offset,h/2]) cylinder(r=motor_r,h=h,center=true);
		motor_holes(h=h);
	}
}
			
module motor_mount(h=cam_thickness,r=motor_bolt_r+bvm_c*2){
	for (x=[-1,1]) for (y=[0,1]) translate([x*motor_mount_x/2,-cam_y_offset-motor_mount_offset+motor_mount_y*y,h/2]) cylinder(r=r,h=h,center=true);
}


module motor_holes(h=cam_thickness) {
	translate([0,-cam_y_offset,h/2]) {
		cylinder(r=motor_pilot_r+clearance,h=h+extra,center=true);
		for (x=[-1,1]) for(y=[0,1]) translate([x*motor_mount_x/2,-motor_mount_offset+motor_mount_y*y,0]) {
			cylinder(r=motor_bolt_r,h=h+extra,center=true);
		}
	}
}

module base_holes(h=cam_thickness) {
	for (x=[-1,1]) translate([x*arm_x_offset,0,h/2]) {
		cylinder(r=bolt_r,h=h+extra,center=true);
	}
	if (0) for (x=[-1,1]) translate([x*x_pos,y_pos,h/2]) {
		cylinder(r=bolt_r,h=h+extra,center=true);
	}
	translate([0,-cam_y_offset-cam_bearing_offset,h/2]) cylinder(r=bolt_r*1.5,h=h+extra,center=true);
	for (x=[-1,1]) translate([x*chest_bar_l/2,y_pos-bvm_c*2,h/2]) cylinder(r=bolt_r,h=h+extra,center=true);
}

module bag_mount(w=arm_w) {
	union() {
		translate([bvm_r+bearing_h/2,0,bearing_h/2]) scale([1,bvm_l/1.7/bvm_r,1]) {
			union() {
				intersection() {
					difference() {
						translate([0,1.2,0]) cylinder(r=bvm_r+w,h=bearing_h,$fn=$fn*2,center=true);
						cylinder(r=bvm_r,h=bearing_h+extra*2,$fn=$fn*2,center=true);
					}
					intersection() {
						translate([-bvm_r-bvm_tr/1.1,-bvm_r,0]) cube([bvm_r*2,bvm_r*2,bearing_h+extra*3],center=true);
					}
				}
				translate([-bvm_tr/1.5-bearing_h/2,-bvm_r,0]) difference() {
					hull() for (x=[-1,1]) for(y=[-1,1]) translate([x*(bearing_h/4),bearing_h/4*y,0]) cylinder(r=cam_thickness,h=bearing_h,center=true);
					hull() for(y=[-1,1]) translate([0,bearing_h/8*y,0]) cylinder(r=cam_thickness/2,h=bearing_h+extra,center=true);
				}
			}
		}
		hull() {
			translate([-bearing_h/1.9/2-arm_w,3,bearing_h/2]) cube([bearing_h*1.5-clearance,bearing_h*1.5-clearance/2,bearing_h+extra],center=true);
			translate([bearing_h/3,-25,bearing_h/2]) cube([clearance/2,bearing_h*1.5-clearance/2,bearing_h+extra],center=true);
		}
	}
}
				
module paddle(laser=1) {
	difference() {
		union() {
			scale([paddle_scale,paddle_scale,1]) intersection() {
				translate([0,0,-bvm_r/2+bvm_r/6]) sphere(r=bvm_r/2,center=true);
				translate([0,0,bvm_r/2]) cylinder(r=bvm_r/3,h=bvm_r,center=true);
			}
		}
		if (! laser) union() {
			difference() {
				scale([paddle_scale,paddle_scale,1]) intersection() {
					translate([0,0,-bvm_r/2+bvm_r/6-paddle_t-extra]) sphere(r=bvm_r/2,center=true);
					translate([0,0,bvm_r/2-extra]) cylinder(r=bvm_r/3-paddle_t,h=bvm_r,center=true);
				}
				for (x=[0:bvm_r/8:bvm_r]) translate([-bvm_r/2+x,0,0]) cube([paddle_rib_w,bvm_r,bvm_r],center=true);
				for (y=[0:bvm_r/8:bvm_r]) translate([0,-bvm_r/2+y,0]) cube([bvm_r,paddle_rib_w,bvm_r],center=true);
				hull() {
					for (z=[0,bvm_c*1.5]) translate([0,0,z]) rotate([0,90,0]) cylinder(r=bvm_c*1.5+clearance/2+paddle_rib_w,h=bearing_h+clearance/4+paddle_rib_w*2,center=true);
				}
			}
		}
		if (1) hull() {
			for (z=[0,bvm_c*1.5]) translate([0,0,z]) rotate([0,90,0]) cylinder(r=bvm_c*1.5+clearance/2,h=bearing_h+clearance/4,center=true);
		}
	}
}

module cam_assembly(explode=0) {
	translate([0,0,-explode*2-cam_h/2]) cam(explode=explode);
	for(i=[-1,1]) translate([0,cam_bearing_offset*i,0]) bearing();
	translate([0,0,explode*2+cam_h/2]) rotate([0,180,0]) cam(explode=explode);
}
	
module cam_model(over_r=0,over_h=0,rot=0) {
	union() { 
		hull() {
			rotate([0,0,cam_pre_rot]) translate([0,-cam_bearing_offset,bearing_h/2]) cylinder(r=bearing_or+over_r,h=bearing_h+over_h,center=true,$fn=30);
			//rotate([0,0,cam_pre_rot+rot]) translate([0,-cam_bearing_offset,bearing_h/2]) cylinder(r=bearing_or+over_r,h=bearing_h+over_h,center=true,$fn=16);
		}
		hull() {
			rotate([0,0,cam_pre_rot]) translate([0,cam_bearing_offset,bearing_h/2]) cylinder(r=bearing_or+over_r,h=bearing_h+over_h,center=true,$fn=30);
			//rotate([0,0,cam_pre_rot+rot]) translate([0,cam_bearing_offset,bearing_h/2]) cylinder(r=bearing_or+over_r,h=bearing_h+over_h,center=true,$fn=16);
		}
		rotate([0,0,cam_pre_rot]) hull() for(i=[-1,1]) translate([0,cam_bearing_offset*i,bearing_h/2]) cylinder(r=bearing_or/1.25+over_r,h=bearing_h+over_h,center=true,$fn=8);
	}
}


module bearing(outer=bearing_or*2,inner=bearing_ir*2,width=bearing_h) {
	difference() {
		union() {
			color("grey") difference() {
				cylinder(r=outer/2,h=width,center=true);
				cylinder(r=outer/2.3,h=width+extra,center=true);
			}
			color("grey") difference() {
				cylinder(r=inner/1.4,h=width,center=true);
				cylinder(r=inner/2,h=width+extra,center=true);
			}
			color("orange") cylinder(r=outer/2-extra*4,h=width*.9,center=true);
		}
		color("grey") cylinder(r=inner/2,h=width+extra,center=true);
	}
}

module arm_model() {
	y_pos=-cam_y_offset-cam_l/2;
	difference() {
		union() {
			// end_mounts
			if (1) hull() {
				translate([arm_x_offset-bvm_r,bvm_r+bvm_y_offset+bearing_or+arm_w,bearing_h/2]) cylinder(r=bvm_c*1.5,h=bearing_h,center=true);
				translate([arm_x_offset-bvm_r-arm_w*3.7,bvm_r+bvm_y_offset+bearing_or+arm_w/2,bearing_h/2]) cylinder(r=bvm_c*1.5,h=bearing_h,center=true);
			}
			// outer rib
			hull() {
				if (1) hull() {
					translate([arm_x_offset-bearing_or*1.5+arm_w*2,y_pos,bearing_h/2]) cylinder(r=arm_w,h=bearing_h,center=true);
					translate([arm_x_offset,bvm_r+bearing_or+arm_w+bvm_y_offset,bearing_h/2]) rotate([0,0,-70]) translate([0,-bvm_r-arm_w*3.44,0]) cylinder(r=arm_w,h=bearing_h,center=true);
				}
				// middle rib
				if (1) hull() {
					translate([arm_x_offset-arm_w,-cam_y_offset,bearing_h/2]) cylinder(r=arm_w/2,h=bearing_h,center=true);
					translate([arm_x_offset,bvm_r+bearing_or+arm_w+bvm_y_offset,bearing_h/2]) rotate([0,0,-60]) translate([0,-bvm_r-arm_w*3.44,0]) cylinder(r=arm_w/2,h=bearing_h,center=true);
				}
				// inner rib
				if (1) hull() {
					translate([arm_x_offset,bvm_r+bearing_or+arm_w+bvm_y_offset,bearing_h/2]) rotate([0,0,-50]) translate([0,-bvm_r-arm_w*2.44,0]) cylinder(r=arm_w/2,h=bearing_h,center=true);
					rotate([0,0,-50]) translate([0,bearing_or+arm_w/2,bearing_h/2]) cylinder(r=arm_w/2,h=bearing_h,center=true);
				}

				// cross rib
				if (1) hull() {
					translate([0,0,bearing_h/2]) cylinder(r=arm_w/2,h=bearing_h,center=true);
					translate([-arm_x_offset*1.25,0,bearing_h/2]) cylinder(r=arm_w/2,h=bearing_h,center=true);
				}
			}
			// end curve
			if (1) translate([arm_x_offset,bvm_r+bearing_or+arm_w+bvm_y_offset,bearing_h/2]) intersection() {
				difference() {
					cylinder(r=bvm_r+arm_w*4.5,h=bearing_h,$fn=$fn*2,center=true);
					cylinder(r=bvm_r+arm_w*2,h=bearing_h+extra*2,$fn=$fn*2,center=true);
				}
				intersection() {
					translate([-bvm_r,-bvm_r,0]) cube([bvm_r*2,bvm_r*2,bearing_h+extra*3],center=true);
					rotate([0,0,-50]) translate([-bvm_r,-bvm_r,0]) cube([bvm_r*2,bvm_r*2,bearing_h+extra*4],center=true);
				}
			}
			// cam drive and bearing mount
			if (1) hull() {
				translate([0,0,bearing_h/2]) cylinder(r=bearing_or+arm_w,h=bearing_h,center=true);
				translate([arm_x_offset-bearing_or,-cam_y_offset,bearing_h/2]) {
					translate([bearing_or/2-clearance,0,0])  rotate([0,0,cam_pre_rot]) cube([bearing_or,cam_l+arm_w*2,bearing_h],center=true);
					translate([0,(cam_l/2-bearing_or)*-1,0]) cylinder(r=bearing_or/2, h=bearing_h,center=true);
				}
			}
		}
		rot=0;
		// cam cutout
		if (1) for (i=[0:path_step:180]) {
			if (i<comp_rot) {
				rotate([0,0,i/(comp_rot/arm_rot)]) translate([arm_x_offset,-cam_y_offset,0]) rotate([0,0,-i-rot]) cam_model(over_h=extra*4,over_r=0,rot=rot);
			} else {
				rotate([0,0,comp_rot/(comp_rot/arm_rot)*2-i/(comp_rot/arm_rot)]) translate([arm_x_offset,-cam_y_offset,0]) rotate([0,0,-i-rot]) cam_model(over_h=extra*4,over_r=0,rot=rot);
			}
		}
		// bearing cutout
		intersection() {
			translate([0,0,bearing_h/2]) cylinder(r=bearing_or+clearance/4,h=bearing_h+extra*2,center=true);
			translate([0,0,bearing_h/2]) cube([bearing_or*2-clearance/8,bearing_or*2,bearing_h+extra*2],center=true);
		}
	}
}

module arm_l() {
	arm_model();
}
 
module arm_r() {
	mirror([1,0,0]) arm_model();
}
 
module cam(h=cam_thickness,explode=0) {
	union() {
		translate([0,0,-explode]) cam_plate();
		translate([0,0,h-extra]) {
			for (y=[-1,1]) translate([0,cam_bearing_offset*y,0]) {
				translate([0,0,explode+bearing_washer_h]) bearing_bushing(h=bearing_h/2+extra*2);
				bearing_washer();
			}
			translate([0,0,explode+bearing_washer_h]) cam_center();
			cam_center(h=bearing_washer_h);
			
		}
	}
}
module cam_plate(h=cam_thickness) {
	difference() {
		union() {
			for(y=[-1,1]) translate([0,cam_bearing_offset*y,h/2]) cylinder(r=bearing_or-clearance*3,h=h,center=true);
			hull() for(y=[-1,1]) translate([0,cam_bearing_offset*y,h/2]) cylinder(r=bearing_or/1.25-clearance,h=h,center=true);
		}
		cam_holes(h=cam_thickness);
	}
}

module cam_holes() {
	for(y=[-1,1]) translate([0,cam_bearing_offset*y,cam_h/4]) cylinder(r=bolt_r,h=cam_h,center=true);
	// D shaft
	intersection() {
		translate([0,0,cam_h/2]) cylinder(r=motor_shaft_r+clearance/4,h=cam_h+extra,center=true);
		translate([0,motor_shaft_r/2-motor_shaft_r/3,cam_h/2]) cube([motor_shaft_r*2,motor_shaft_r*2,cam_h+extra*4],center=true);
	}
}

module cam_center(h=bearing_h/2) {
	difference() {
		cam_plate(h=h);
		for(i=[-1,1]) translate([0,cam_bearing_offset*i,h/2]) {
			cylinder(r=bearing_or+clearance,h=h+extra,center=true);
			cube([bearing_or*2,bearing_or*1.5,h+extra],center=true);
		}
	}
}
	

