function in(in) = in*25.4;
// Converts a hexagon's minor radius/diameter to major
function hex_major(minor) = minor*2/sqrt(3);
$fa=1;
$fs=.5;
fudge=0.5;
tolerance=.1;
slant=2;
foot_thick=.2;
foot_radius=5;


include <controller_sockets.scad>;
include <teensy.scad>;
include <pins.scad>;

csy=ps*5.5/2;
csx=ps*14/2;

//Center to handle
//N64 and NES-first
ctoh_N64=24.130;
ctoh_NES=21.590;
ctoh_bot=in(0.2625)+ps;
ctoh_top=in(0.3125)+ps;

board_clearance=0.5;
board_length=69.85;
board_width=24.13;
board_thick=in(.063);
board_offset=5;
ledge_width=2.5;

child_length=80.01;
child_width=15.875;
child_clearance=3;
child_offset=2.3;
board_to_child_top=10.22;
child_top_to_pins=8.255;

sideport_width=21.35;
sideport_height=2.6+0.5;
sideport_offset=22.86; // center of board to center of connector

socket_thick=2.5;
box_thick=2.5;
box_height=
    box_thick+
    board_offset+
    board_thick+
    teensy_total_height;

//helper
board_top =
    box_thick +
    board_offset +
    board_thick;

top_to_teensy=in(0.05);
bottom_to_teensy=in(0.075);
teensy_margin=1;
teensy_hole_height = max(
    teensy_total_height,
    box_height - board_top - box_thick
);
bottom_height=box_height-socket_depth-socket_thick;

side_offset=board_top+(board_to_child_top-child_top_to_pins);
side_ceiling=max(ps+NES_corner_radius, N64_width/2)+socket_thick;
socket_breadth=side_ceiling+SNES_corner_radius+socket_thick;

side_thick=min(3.5, side_offset-(child_width-child_top_to_pins));
side_length=child_length+side_thick*2;
side_width=side_offset+side_ceiling;
side_height=socket_depth+socket_thick+pin_base_height+board_thick+child_offset;

box_length=child_length+side_thick*2;
box_width=board_width+board_clearance*2;

teensy_trans=(bottom_to_teensy-top_to_teensy)/2;
center_to_teensy=-2.54;
outside_to_teensy = box_length/2 - teensy_length - center_to_teensy;

teensy_top=board_top +
    teensy_height +
    board_thick;

cable_width=12;
cable_height=10;

//Size of outer cutout box
cutout_size=[
    teensy_width+teensy_margin*2,
    bottom_to_teensy+box_thick+board_clearance/2,
    teensy_hole_height - (bottom_height - board_top),
];
//Thickness of wall between teensy and connector
cutout_thick = 1;
//Moves from lying on the +X/+Y/+Z corner)
cutout_pos=[-cutout_size[0]/2,-box_width/2,bottom_height];

holder_offset=board_top+ledge_width/2;
holder_height=box_height-(socket_depth+socket_thick+holder_offset);
holder_clearance=0.5;

lid_slot_width=5;

module trans_side_cover() {
    bothsides(box_width)
    translate([0,-side_height,side_offset])
    rotate([90,0,180])
    children();
}

module wedge(width, length, angle=45) {
    dims = [width, length, width];
    translate([0,-length/2,-width])
    intersection() {
        cube(size=dims);
        rotate([0,-angle,0])
        translate([-width*(2-sqrt(2))/2,-length/2,0])
        cube(size=dims*2);
    }
}
module lump(solid=true) {
    translate([-ps*3,0,0]) {
        translate([0,0,0]) NES(solid);
        translate([0,0,0]) SNES(solid);
        translate([ps*4+SNES_gap,0,0]) N64(solid);
    }
}
module lump_top() {
    translate([-ps*3,0,0]) {
        translate([ps*1.5,ps*(.5),0]) NES_top();
        translate([tpw/2,0,0]) SNES_top();
        translate([ps*4+SNES_gap,0,0]) N64_top();
    }
}

module timestwo() {
    translate([-ctoh_N64,0,0]) children();
    translate([ctoh_NES,0,0]) children();
}

module side_cover() {
  extension_height=box_height-side_offset-side_ceiling+box_thick;

  module grabber() {
    /* Grabber */
    grabber_width=10;
    grabber_length=5;
    bump_size=2;
    translate([0,-box_thick,-grabber_length/2]) {
      translate([-grabber_width/2,0,0])
      cube(size=[grabber_width,box_thick,grabber_length*1.5]);

      translate([0,box_thick,grabber_length*1.5-bump_size/2*sqrt(2)])
      rotate([45,0,0])
      cube(size=[grabber_width,bump_size,bump_size],center=true);

      translate([0,box_thick,0])
      rotate([0,0,-90])
      wedge(box_thick, grabber_width);
    }
  }

  module half_lid() {
    translate([0,side_ceiling,0]) {
      bothends(side_length) {
        translate([0,0,extension_height*sqrt(3)])
        cube([side_thick,extension_height,side_height-extension_height*sqrt(3)]);
        translate([side_thick/2,0,extension_height*sqrt(3)])
        rotate([0,0,90])
        wedge(extension_height*sqrt(3),side_thick,60);
      }
      difference() {
        translate([-side_length/2,0,0]) {
          intersection() {
            slant_thick=box_thick/2*sqrt(3); // trig magic
            rotate([-30,0,0])
            translate([0,-slant_thick,0])
            cube([side_length,slant_thick,extension_height*2]);
            cube([side_length,extension_height,extension_height*sqrt(3)]);
          }
          translate([0,extension_height-box_thick,extension_height*sqrt(3)])
          cube([side_length,box_thick,side_height-extension_height*sqrt(3)+box_width/2]);
        }
        bothends(side_length)
        translate([0,5,side_height+box_width/2])
        cube([(outside_to_teensy-connector_overhang)*2,cable_height,cable_width],center=true);
      }
    }
  }

  module socket_wall() {
    minkowski() {
      linear_extrude(height=socket_depth)
      mirror([1,0,0]) timestwo() lump();
      cylinder(h=socket_thick, r=socket_thick);
    }
  }
  
  difference() {
    union() {
      //Main frame of the box
      translate([-side_length/2,-side_offset,0])
      difference() {
        cube(size=[
          side_length,
          side_width,
          side_height
        ]);
        translate([side_thick,side_thick-fudge,side_thick-fudge])
        cube(size=[
          side_length-side_thick*2,
          side_width-side_thick+fudge*2,
          side_height
        ]);
      }
      // Socket walls
      socket_wall();
      // Join the bottom wall to the sockets
      difference() {
        join_width=side_offset-side_thick-SNES_corner_radius;
        translate([-side_length/2,-side_offset+side_thick,0])
        cube(size=[side_length,join_width,socket_depth+socket_thick]);
        socket_wall();
      }
    }

    // Sockets
    translate([0,0,-fudge])
    linear_extrude(height=socket_depth*2)
    mirror([1,0,0]) timestwo() lump();

    // Bevel
    mirror([0,0,1])
    translate([0,0,-slant])
    mirror([1,0,0]) timestwo()
    minkowski() {
      cylinder(h=slant,r1=0,r2=slant);
      linear_extrude(height=1)
      lump();
    }

    // Socket lid slots
    translate([0,0,socket_depth])
    timestwo() {
      translate([-lid_slot_width/2,-socket_breadth/2,0]) {
        translate([-ps*2,0,0])
        cube([lid_slot_width,socket_breadth+socket_thick*2,socket_thick*2]);
        translate([SNES_gap,0,0])
        cube([lid_slot_width,socket_breadth+socket_thick*2,socket_thick*2]);
      }
    }

    side_tabs(1);
  }


  difference() {
    half_lid();
    translate([
      side_length/4,
      side_ceiling+extension_height-box_thick,
      side_width+box_width/2
    ])
    rotate([0,180,0])
    grabber();
  }

  translate([
    -side_length/4,
    side_ceiling+extension_height-box_thick,
    side_width+box_width/2])
  grabber();

  
  /* Board holders */
  translate([0,child_top_to_pins-child_width/2,0])
  bothsides(child_width) bothends(child_length)
  translate([0,-3,side_thick])
  cube(size=[3,3,side_height-side_thick]);
}

module socket_slots(height) {
  timestwo() {
    translate([-lid_slot_width/2,-(socket_breadth-side_ceiling),0]) {
      translate([-ps*2,0,0])
      cube([lid_slot_width,socket_breadth,height]);
      translate([SNES_gap,0,0])
      cube([lid_slot_width,socket_breadth,height]);
    }
  }
}

module socket_plates() {
  difference() {
    union() {
      linear_extrude(height=socket_thick)
      mirror([1,0,0])
      timestwo() lump();

      socket_slots(socket_thick);
    }
    
    linear_extrude(height=socket_thick+fudge*2)
    mirror([1,0,0])
    timestwo() pin_cutout();
  }

}

// Thicken cause cutouts are weird sometimes
module side_tabs(thicken=0) {
  bothends(side_length) {
    height=5;
    translate([0,0,side_height]) {
      translate([-thicken/2,0,-height/2])
      rotate([45,0,0])
      cube(size=[side_thick+thicken,height/sqrt(2),height/sqrt(2)]);
    }
  }
}

module box_bottom() {
  module box_base() {
    difference() {
        translate([-box_length/2,-box_width/2,0])
        difference() {
            translate([0,0,0])
            cube(size=[box_length,box_width,box_height]);
            translate([box_thick*2,box_thick,box_thick])
            cube(size=[box_length-box_thick*4,box_width-box_thick*2,box_height]);
            translate([box_thick*2,-fudge,box_thick+board_offset])
            cube(size=[box_length-box_thick*4,box_width+fudge*2,box_height]);
            translate([0,box_width/2,teensy_top])
            translate([box_thick,0,connector_size[2]/2])
            cube(size=[box_thick*2+fudge*2, cable_width, cable_height], center=true);
        }
    }
  }

  module usb_holder() {
    // USB holder thing
    intersection() {
        translate([0,0,box_height/2])
        cube(size=[box_length,box_width,box_height],center=true);

        translate([
            -box_length/2,
            0,
            teensy_top
        ])
        rotate([0,0,-90])
        union() {
            translate([0,outside_to_teensy/2,connector_size[2]/2])
            difference() {
                cube(size=[
                    cable_width+box_thick*2,
                    outside_to_teensy,
                    cable_height+box_thick*2
                ],center=true);
                translate([0,-connector_overhang/2-fudge/2,0])
                cube(size=[
                    cable_width,
                    outside_to_teensy-connector_overhang+fudge,
                    cable_height
                ],center=true);
                translate([0,0,connector_size[2]/2])
                cube(size=[
                    connector_size[0],
                    outside_to_teensy+fudge*2,
                    connector_headroom
                ],center=true);
            }
        }
    }

    translate([-box_length/2,0,teensy_top+connector_size[2]/2-cable_height/2-box_thick])
    wedge(outside_to_teensy, cable_width+box_thick*2);
  }

  module usb_mirror_lump() {
    depth=outside_to_teensy-connector_overhang;
    translate([box_length/2,0,box_height]) {
      mirror([1,0,0]) {
        translate([0,-cable_width/2,0])
        cube([depth,cable_width,box_thick]);
        wedge(depth,cable_width);
      }
    }
  }

  module bolt_holder() {
    nut_width=hex_major(4);
    nut_thick=1.51;
    bolt_dia=2;
    bolt_below_board=3.6;
    roof_thick=1;
    wall_thick=0.5;
    post_width=nut_width+wall_thick*2;

    nut_base=board_offset-bolt_below_board;
    post_height=nut_base+nut_thick*1.1+roof_thick;

    difference() {
      translate([0,0,post_height/2])
      cube(size=[post_width,post_width,post_height],center=true);
      translate([0,0,nut_base]) {
        rotate([0,0,30])
        cylinder(h=nut_thick*1.1,d=nut_width*1.1,$fn=6);
        cylinder(h=post_height,d=bolt_dia*1.1);
      }
    }
  }

  difference() {
    union() {
      box_base();
      usb_holder();
      usb_mirror_lump();
      trans_side_cover() side_tabs();
    }

    /* Side ports */
    translate([0,0,box_thick+board_offset-sideport_height])
    bothsides(box_width) bothends(board_length)
    translate([
        board_length/2-(sideport_offset+sideport_width/2),
        -fudge,
        0
    ])
    cube(size=[sideport_width+board_clearance,box_thick+fudge*2+tolerance,sideport_height*2]);
  }

  translate([-9.525,3.175,box_thick])
  bolt_holder();
  translate([9.525,-5.334,box_thick])
  bolt_holder();
}

module bothsides(width=box_width-box_thick*2) {
    translate([0,-width/2,0])
    children(); 
    translate([0,width/2,0])
    mirror([0,1,0])
    children(); 
}

module bothends(length=box_length-box_thick*2) {
    translate([-length/2,0,0])
    children();
    translate([length/2,0,0])
    mirror([1,0,0])
    children();
}

module box() {
    //translate([0,0,50])
    union() { box_top(); }
    union() { box_bottom(); }
}

module board() {
    union() {
        //Board
        color("darkgreen")
        translate([0,0,board_top - board_thick/2])
        cube(size=[
            board_length,
            board_width,
            board_thick
        ], center=true);
    }
}

module child_board() {
  color("darkgreen") {
    translate([0,child_top_to_pins-child_width/2,socket_depth+socket_thick+pin_base_height])
    cube(size=[child_length,child_width,board_thick],center=true);
  }
}

module solder_helper() {
  helper_width=ps*9;
  popup_height=0.2;
  helper_height=pin_plastic+board_thick-popup_height;
  helper_length=teensy_length*2;
  shelf_width=1;

  nut_thick=2.28;
  nut_width=hex_major(5.4);
  nut_clearance=0.5;
  nut_offset=(helper_height-nut_thick-nut_clearance*2)/2;

  module slot(width, length) {
    translate([0,0,board_thick])
    cube(size=[width,length,helper_height*2]);
    translate([0,shelf_width,0])
    cube(size=[width,length-shelf_width*2,helper_height*2]);
  }

  module slotpair(width, length, outside) {
    translate([outside/2-width,0,0])
    slot(width, length);
    translate([-outside/2,0,0])
    slot(width, length);
  }

  difference() {
    cube(size=[helper_width, helper_length, helper_height]);

    translate([helper_width/2,5,0])
    difference() {
      slotpair(header_thick, teensy_length, teensy_width);

      translate([0,teensy_length/2,0])
      bothsides(teensy_length)
      bothends(teensy_width-header_thick)
      bothends(header_thick) cube(size=[0.8,in(0.4),board_thick]);
    }

    pin_length=1.9; // clipped :/
    port_elevate=pin_length-board_thick+0.1;

    port_width=8.4;
    port_length=20.8;
    port_overhang=2;
    port_sep=6.730;
    port_total_width=port_sep+port_width*2;
    echo(port_elevate);
    translate([helper_width/2,5+(teensy_length-port_length)/2,-port_elevate]) {
      slotpair(port_width, port_length, port_total_width);
      translate([0,shelf_width,0])
      slotpair(port_overhang,port_length-shelf_width*2,port_sep+0.01);
    }


    base_width=6.9; // from datasheet
    pins_to_header=5.080;
    edge_to_header=ps*3.5-7.620-header_thick/2;
    multiport_width=ps*6+SNES_gap;
    translate([(helper_width-multiport_width)/2,teensy_length+10+ps*3,0])
    rotate([0,0,-90]) {
      slot(base_width, ps*4);
      translate([0,ps*3+SNES_gap,0])
      slot(base_width, ps*3);
      translate([0,ps,0])
      slot(base_width+ps, ps*3);

      header_width=in(0.8);
      header_offset=5.080; // measured from pin to pin
      pin_clearance=1;
      translate([(base_width/2-header_thick/2)-header_offset, multiport_width/2-header_width/2+in(0.05),helper_height-pin_clearance])
      cube(size=[header_thick,header_width,pin_clearance*2]);
      translate([-5, multiport_width/2-header_width/2+in(0.05),0])
      slot(header_thick, header_width);
    }

    inset=4;
    translate([helper_width/2,helper_length/2,0])
    bothsides(helper_length-inset*2) bothends(helper_width-inset*2)
    cylinder(d=3,h=nut_offset);

    translate([helper_width/2,helper_length/2,nut_offset])
    bothsides(helper_length-inset*2) bothends(helper_width-inset*2)
    cylinder(d=nut_width+nut_clearance,h=nut_thick,$fn=6);
  }

  // posts
  helper_offset=pin_length*1.1;
  *translate([-15,10,0])
  bothsides(20) bothends(20) {
    union() {
      cylinder(d=3,h=helper_height+helper_offset);
      cylinder(r=4,h=helper_offset);
    }
  }
  
}

*solder_helper();

//Socket mockups
*color("dimgray")
translate([0,0,box_height])
linear_extrude(height=socket_depth)
timestwo() lump_top();


//trans_side_cover()
!side_cover();

*socket_plates();

*box_bottom();
*board();
*translate([
    -center_to_teensy-teensy_length,
    teensy_width/2,
    board_top
]) rotate([0,0,-90]) teensy();
*intersection() {
    union() {
        box();
    }
    //translate([box_length*$t-box_length/2,0,box_height/2])
    translate([0,0,box_height*$t])
    //cube([box_length/$ns,box_width,box_height],center=true);
    cube([box_length,box_width,box_height/$ns],center=true);
}

*difference() {
    box();
    translate([-box_length/2,0,0])
    cube([box_length,box_width,box_height]);
}

*translate([0,10,box_height-(5.8+1.5)])
cylinder(r=6,h=5.8+1.5);
