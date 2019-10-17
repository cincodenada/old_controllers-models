function in(in) = in*25.4;
$fa=1;
$fs=.5;
fudge=0.5;
tolerance=.5;
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
child_width=20.320;
child_clearance=3;
child_offset=2.3;
board_to_child_top=10.22;
child_top_to_pins=8.255;

sideport_width=21.35;
sideport_height=2.6+0.5;
sideport_offset=22.86; // center of board to center of connector

socket_thick=1.5;
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

box_length=child_length+box_thick*2+board_clearance*2;
box_width=board_width+board_clearance*2;

teensy_trans=(bottom_to_teensy-top_to_teensy)/2;
center_to_teensy=2.54;

teensy_top=board_top +
    teensy_height +
    board_thick;

cable_width=12;
cable_height=9;

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

module wedge(width, length) {
    dims = [width, length, width];
    translate([0,-length/2,-width])
    intersection() {
        cube(size=dims);
        rotate([0,-45,0])
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
        %translate([ps*1.5,ps*(.5),0]) NES_top();
        translate([tpw/2,0,0]) SNES_top();
        translate([ps*4+SNES_gap,0,0]) N64_top();
    }
}

module timestwo() {
    translate([-ctoh_N64,0,0]) children(0);
    translate([ctoh_NES,0,0]) children(0);
}

module connector_cap() {
    translate([0,-fudge,0])
    translate([
        (cutout_size[0]-connector_size[0])/2,
        cutout_size[1] - cutout_thick,
        teensy_top + connector_size[2] - bottom_height,
    ])
    cube(size=[
        connector_size[0],
        cutout_thick,
        box_height-teensy_top-connector_size[2]
    ] + [0,fudge*2,fudge]);
}

module grab_top() {
    grab_r = ledge_width/2;
    translate([
        0,
        ledge_width,
        box_thick-grab_r+
        board_offset-ledge_width
    ])
    rotate([90,0,0])
    cylinder(h=ledge_width, r=grab_r);
}

module grab_bottom() {
    translate([0,0,box_thick+board_offset-ledge_width])
    cube(ledge_width);
}

module side_cover() {
    socket_depth=5;
    box_length=child_length+box_thick*2;
    box_width=child_width;
    box_height=socket_depth+socket_thick+pin_base_height+board_thick+child_offset;
    difference() {
        union() {
            //Main frame of the box
            translate([-box_length/2,-box_width/2,0])
            difference() {
                translate([0,0,0])
                cube(size=[
                    box_length,
                    box_width,
                    box_height
                ]);
                translate([box_thick,-fudge,socket_thick+socket_depth])
                cube(size=[
                    box_length-box_thick*2,
                    box_width+fudge*2,
                    bottom_height
                ]);
            }
        }
        union() {
          translate([0,0,-fudge])
          linear_extrude(height=socket_depth+fudge)
          timestwo() lump(false);
        }
        translate([0,0,socket_depth-fudge])
        linear_extrude(height=box_thick+fudge*2)
        timestwo() pin_cutout();
    }
    bothends(box_length) {
      overhang=board_width-child_width;
      height=5;
      translate([-box_thick,-height/2,box_height]) {
        cube(size=[box_thick+overhang,height,height]);
        translate([0,height/2,height])
        rotate([0,90,0])
        cylinder(r=height/2, h=box_thick+overhang);
      }
    }

    //Feet
    difference() {
        bothends(box_length) bothsides(box_width)
        cylinder(r=foot_radius,h=foot_thick);
        translate([0,0,0])
        linear_extrude(height=socket_depth+fudge)
        timestwo() lump();
    }

    bothends() {
        bothsides() union() {
            grab_top();
        }
    }
    //}
}

module box_bottom() {
    //color("gold") {
        //Base outline
        difference() {
            translate([-box_length/2,-box_width/2,0])
            difference() {
                translate([0,0,0])
                cube(size=[box_length,box_width,box_height]);
                translate([box_thick,box_thick,box_thick])
                cube(size=[box_length-box_thick*2,box_width-box_thick*2,box_height]);
                translate([box_thick,-fudge,box_thick+board_offset])
                cube(size=[box_length-box_thick*2,box_width+fudge*2,box_height]);
                translate([0,box_width/2,teensy_top])
                translate([box_thick/2,0,connector_size[2]/2])
                cube(size=[box_thick+fudge*2, cable_width, cable_height], center=true);
    /*
                translate([-fudge,-fudge,0])
                translate([0,0,box_thick])
                cube([box_thick,box_width,box_height] + [fudge,fudge*2,0]);
                translate([0,-fudge,0])
                translate([box_length-box_thick,0,box_thick])
                cube([box_thick,box_width,box_height] + [fudge,fudge*2,0]);
    */
            }
            bothsides() bothends()
            translate([
                // bothsides/ends is relative to box, not board
                (child_length-board_length)+
                (board_length/2+board_clearance-sideport_offset-sideport_width/2),
                -box_thick-fudge,
                box_thick+board_offset-sideport_height
            ])
            cube(size=[sideport_width+board_clearance,box_thick+fudge*2,sideport_height+fudge]);    
        }

        // USB holder thing
        outside_to_teensy = box_length/2 - teensy_length - center_to_teensy;
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
                    cube(size=[
                        cable_width,
                        outside_to_teensy+fudge*2,
                        cable_height
                    ],center=true);
                }
                translate([0,outside_to_teensy-connector_overhang/2,connector_size[2]/2])
                difference() {
                    cube(size=[
                        cable_width+box_thick*2,
                        connector_overhang,
                        cable_height+box_thick*2
                    ],center=true);
                    cube(size=[
                        connector_size[0],
                        connector_overhang+fudge*2,
                        connector_size[2]
                    ],center=true);
                }
            }
        }

        translate([-box_length/2,0,teensy_top+connector_size[2]/2-cable_height/2-box_thick])
        wedge(outside_to_teensy, cable_width+box_thick*2);

/*
        //Top holder
        bothends() {
            bothsides() union() {
                grab_bottom();
            }
        }

        //Feet
        bothends() bothsides()
        translate([-wall_thick,-wall_thick,0])
        cylinder(r=foot_radius,h=foot_thick);
*/
    //}
}

module bothsides(width=box_width) {
    translate([0,-(width/2-box_thick),0])
    children(0); 
    translate([0,width/2-box_thick,0])
    mirror([0,1,0])
    children(0); 
}

module bothends(length=box_length) {
    translate([-(length/2-box_thick),0,0])
    children(0);
    translate([length/2-box_thick,0,0])
    mirror([1,0,0])
    children(0);
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

        //Teensy
        translate([
            -teensy_width/2,
            teensy_trans-teensy_length/2,
            board_top
        ])
        teensy_headers();
    }
}

module solder_helper() {
  helper_width=ps*9;
  helper_height=pin_plastic+board_thick;
  helper_length=teensy_length*2;
  shelf_width=1;

  module slot(width, length) {
    translate([0,0,board_thick])
    cube(size=[width,length,helper_height*2-board_thick]);
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
    slotpair(header_thick, teensy_length, teensy_width);


    pin_length=1.16;
    port_elevate=pin_length-board_thick+0.2;

    port_width=8.4;
    port_length=20.8;
    port_overhang=1.5; 
    port_sep=6.730;
    port_total_width=port_sep+port_width*2;
    echo(port_elevate);
    translate([helper_width/2,5+(teensy_length-port_length)/2,port_elevate]) {
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
      translate([-5, multiport_width/2-header_width/2,0])
      slot(header_thick, header_width);
    }

    inset=-box_thick+4;
    translate([helper_width/2,helper_length/2,0])
    bothsides(helper_length-inset*2) bothends(helper_width-inset*2)
    cylinder(d=3,h=helper_height);
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

solder_helper();

//Socket mockups
*color("dimgray")
translate([0,0,box_height])
linear_extrude(height=socket_depth)
timestwo() lump_top();

*board();

*rotate([-90,0,0])
*side_cover();
*box_bottom();
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
