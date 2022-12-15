// 12.11.2022
// Siehe Rotation Matrix in Wikipedia

// View Space: The world space vertex positions relative to the view of the camera

/* Die Verdeckungsberechnung ist zum korrekten Rendern einer 3D-Szene notwendig, weil Oberflächen,
   die für den Betrachter nicht sichtbar sind, auch nicht dargestellt werden sollten
*/

// ->  https://de.wikipedia.org/wiki/Sichtbarkeitsproblem


// TODO: Raytracing/Verdeckungsberechnung
// TODO: Texture Mapping

import java.util.Arrays;

import java.awt.Robot;


import java.nio.ByteBuffer;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.ArrayList;

byte b[];

int amount = 0;
String lines[];


PVector[][] vertices;
int[] faces;



float a = 0;


PVector cam, cam_angle, cam_move, cam_speed;

float angle = 0.0;


void setup() {
  size(800,600);
  frameRate(60);
  noCursor();

  cam  = new PVector(0, 100, -500);
  cam_angle = new PVector(0, 0, 0);
  cam_move = new PVector(0, 0, 0);
  cam_speed = new PVector(50, 50, 50);
  
  lines =  loadStrings("UM2_SkullPile28mm.obj"); 
 
  println("File loaded. Now scanning contents...");
  
  println();
  
  Pattern numbers = Pattern.compile("(-?\\d+)");
  
  
  ArrayList<PVector> vertices_ = new ArrayList<PVector>();
  ArrayList<ArrayList> faces_ = new ArrayList<ArrayList>();
  
  int parsed_lines = 0; 
  
  for(String i:lines) {
    switch(i.charAt(0)) {
      
      // Find faces
      case 'f':
        ArrayList<Integer> values = new ArrayList<Integer>();
        for(Matcher m = numbers.matcher(i); m.find(); values.add(Integer.parseInt(m.group())));
        faces_.add(values);
        break;
        
      // Find Vectors  
      case 'v':
        String s[] = i.trim().split("\\s+");
        vertices_.add(new PVector(Float.parseFloat(s[1])*20, Float.parseFloat(s[2])*20, Float.parseFloat(s[3])*20));
        break;
    };
    if(++parsed_lines % (lines.length/6) == 0 || parsed_lines == lines.length) println((int)(map(parsed_lines, 0, lines.length, 0, 100)), "%");
  }
  
  println();
  println("Done. Found", vertices_.size(), "Vertices and", faces_.size(), "faces");
  
  

  int i=0;  
  
  vertices = new PVector[faces_.size()][];
  
  for(ArrayList<Integer> f_:faces_) {   
    vertices[i] = new PVector[f_.size()]; 
    int j = 0;
    
    for(int f: f_) {
      PVector v = vertices_.get(f-1);
      vertices[i][j] = Rotate3d_x(v, -90); 
      j++;
    }
    
    i++;
  }
  
}


PVector Rotate2d(PVector p, float a) {
  // a = angle

  float[][] m2 = {
    {cos(a), -sin(a)},
    {sin(a), cos(a)}
  };

  float[][] rotated = matmul(m2, new float[][] {
    { p.x },
    { p.y }
    });

  return new PVector(rotated[0][0], rotated[1][0]);
}


PVector Rotate3d(PVector p, float[][] m2) {

  float[][] rotated = matmul(m2, new float[][] {
    { p.x },
    { p.y },
    { p.z }
    });

  return new PVector(rotated[0][0], rotated[1][0], rotated[2][0]);
}



PVector Rotate3d_x(PVector p, float a) {
  return Rotate3d(p,
    new float[][] {
    {1, 0, 0},
    {0, cos(a), -sin(a)},
    {0, sin(a), cos(a)}
    });
};

PVector Rotate3d_y(PVector p, float a) {
  return Rotate3d(p,
    new float[][] {
    {cos(a), 0, sin(a)},
    {0, 1, 0},
    {-sin(a), 0, cos(a)}
    });
}

PVector Rotate3d_z(PVector p, float a) {
  return Rotate3d(p,
    new float[][] {
    {cos(a), -sin(a), 0},
    {sin(a), cos(a), 0},
    {0, 0, 1}
    });
}

PVector Rotate3d(PVector p, PVector a) {
  return Rotate3d_z( Rotate3d_y(Rotate3d_x(p, a.x), a.y), a.z );
}



// Matrixmultiplikation
float[][] matmul(float[][] m1, float[][] m2) {

  int cols_m1 = m1.length,
    rows_m1 = m1[0].length;

  int cols_m2 = m2.length,
    rows_m2 = m2[0].length;

  try {
    if (rows_m1 != cols_m2) throw new Exception("Rows of m1 must match Columns of m2!");
  }
  catch(Exception e) {
    println(e);
  }


  float[][] res = new float[cols_m2][rows_m2];


  for (int c=0; c < cols_m1; c++) {

    for (int r2=0; r2 < rows_m2; r2++) {

      float sum = 0;
      float[] buf = new float[rows_m1];

      // Multiply rows of m1 with columns of m2 and store in buf
      for (int r=0; r < rows_m1; r++) {
        buf[r] = m1[c][r]* m2[r][r2];
      }

      // Add up all entries into sum
      for (float entry : buf) {
        sum += entry;
      }

      res[c][r2] = sum;
    }
  }

  return res;
}


PVector applyPerspective(PVector p) {
    PVector d = applyViewTransform(p);
    return applyPerspectiveTransform(d);
}

PVector applyViewTransform(PVector p) {
    // c = camera position
    // co = camera orientation / camera rotation
    PVector c = cam;
    PVector co = cam_angle;
 

    // dx, dy, dz     https://en.wikipedia.org/wiki/3D_projection   :   Mathematical Formula
    float[][] dxyz = matmul(
            matmul(new float[][]{
                    {1, 0, 0},
                    {0, cos(co.x), sin(co.x)},
                    {0, -sin(co.x), cos(co.x)}
            }, new float[][]{
                    {cos(co.y), 0, -sin(co.y)},
                    {0, 1, 0},
                    {sin(co.y), 0, cos(co.y)}
            }),

            matmul(new float[][]{
                    {cos(co.z), sin(co.z), 0},
                    {-sin(co.z), cos(co.z), 0},
                    {0, 0, 1}
            }, new float[][]{
                    {p.x - c.x},
                    {p.y - c.y},
                    {p.z - c.z},
            }));

    PVector d = new PVector(dxyz[0][0], dxyz[1][0], dxyz[2][0]);
    return d;
}


PVector applyPerspectiveTransform(PVector d) {
     // e = displays surface pos relative to camera pinhole c
    PVector e = new PVector(0, 0, 300);
    return new PVector((e.z / d.z) * d.x + e.x, (e.z / d.z) * d.y + e.y);
}


void draw() {
  background(255);
  translate(width/2, height/2);
  scale(1,-1); 
  noStroke();
  fill(0, 100, 0, 50);
  
 
  
  PVector[][] points_view = new PVector[vertices.length][];
  
  for(int i=0; i < vertices.length; i++) {
    points_view[i] = new PVector[vertices[i].length];
    for(int j=0; j < vertices[i].length; j++)
    points_view[i][j] = applyViewTransform(Rotate3d_y(vertices[i][j], angle));
  }


    
  
    float nearPlane = 1.0;
    
    
    
    for (int c = 0; c < points_view.length; c++) {
      beginShape();
      
        for (int r = 0; r < points_view[c].length-1; r++) {
            // Alle Punkte verbinden
            //if (i == a) continue;
            
            PVector p0 = points_view[c][r];    
            PVector p1 = points_view[c][r+1];
             
            
             if(p0.z < nearPlane && p1.z < nearPlane){ continue; };
             
           
             if(p0.z >= nearPlane && p1.z < nearPlane)
             p1 = PVector.lerp(p0, p1, (p0.z - nearPlane) / (p0.z - p1.z));
              
             if(p0.z < nearPlane && p1.z >= nearPlane)
             p0 = PVector.lerp(p1, p0, (p1.z - nearPlane) / (p1.z - p0.z));
 
            
            // project
            p0 = applyPerspectiveTransform(p0);
            p1 = applyPerspectiveTransform(p1);
            vertex(p0.x, p0.y);
            vertex(p1.x, p1.y);

        }
        endShape();
    }
    
    
    cam_angle.y+=PI/8;
    

  
}
