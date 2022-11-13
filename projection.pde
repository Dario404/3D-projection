// 12.11.2022
// Siehe Rotation Matrix in Wikipedia

import java.util.Arrays;


PVector[] points;

PVector cam, cam_angle, point;

float angle = 0.0;

void setup() {
  //fullScreen();  
  
  size(1000,400);
  noCursor();

  cam = point = new PVector(0, 0, -1000);
  cam_angle = new PVector(0,0,0);

  points = new PVector[] {
    new PVector(-100, -100, -100),
    new PVector(-100, -100, 100),
    new PVector(-100, 100, -100),
    new PVector(-100, 100, 100),
    new PVector( 100, -100, -100),
    new PVector( 100, -100, 100),
    new PVector( 100, 100, -100),
    new PVector( 100, 100, 100),
  };
  
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



PVector applyPerspective(PVector p) {
   PVector c = cam;
   PVector co = cam_angle;
   PVector e =  new PVector(0, 0, 100);
  // c = camera position
  // co = camera orientation / camera rotation
  // e = displays surface pos relative to camera pinhole c

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

  return new PVector((e.z/d.z)*d.x+e.x, (e.z/d.z)*d.y+e.y);
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





void draw() {
  cam_angle = new PVector(0.01*(mouseY-width/2), 0.01*(mouseX-height/2), 0);
  
  background(255);
  translate(width/2, height/2);
  strokeWeight(1);
  fill(0);

  PVector[] points_projected = new PVector[points.length];

  for (int i=0; i < points.length; i++) {
    points_projected[i] =   applyPerspective(points[i]);
  }

  
  for (int i=0; i < points_projected.length; i++) {    
    for (int a=0; a < points_projected.length; a++) {
      // Alle Punkte verbinden
      line(points_projected[i].x, points_projected[i].y, points_projected[a].x, points_projected[a].y);
    }
  }
  
}



void keyPressed() {
  if (key == 'w') {
    cam.add(Rotate3d(new PVector(0, 0, -20), cam_angle));
  }
  
  if (key == 'a') {
    cam.add(Rotate3d(new PVector(20, 0, 0), cam_angle));

  }
  
  if (key == 's') {
    cam.add(Rotate3d(new PVector(0, 0, 20), cam_angle));

  }
  
  if (key == 'd') {
   cam.add(Rotate3d(new PVector(-20, 0, 0), cam_angle));

  }
  
  
}
