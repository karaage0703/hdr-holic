import controlP5.*;

ControlP5 cp5;
ControlWindow controlWindow;
ControlWindow viewWindow;
Textlabel readmeText;

PImage img0;
PImage img1;
PImage img2;
PImage writeImg;

float scope_ratio = 5; // 1 to 100%

final int low_scope_speed_ratio = 20;
final float low_average_speed_ratio = 0.1;

final int high_scope_speed_ratio = 5;
final float high_average_speed_ratio = 0.1;

int scope_speed_ratio = low_scope_speed_ratio; // 1 to scope
float average_speed_ratio = low_average_speed_ratio; // 0 to picture width

final int max_lum_class = 30; // 1 to 256
int class_th = 20; // class threshold
float a_value = 0.27;
float gamma_u = 0.5;
float gamma_n = 1;
float gamma_o = 0.5;
float color_gain = 1;
final float delta = 0.01;
float[] lut_u = new float[256];
float[] lut_n = new float[256];
float[] lut_o = new float[256];

// hdr image
int[] hdr_img_r;
int[] hdr_img_g;
int[] hdr_img_b;

//Window Size
int size_x = 1024;
int size_y = 768;
int view_width, view_height;

void setup(){
  size(size_x, size_y);

  cp5 = new ControlP5(this);

  controlWindow = cp5.addControlWindow("Tunewindow", 100, 100, 360, 600)
    .hideCoordinates()
    .setBackground(color(40))
    ;

  cp5.addTextlabel("guide")
      .setText("Guide:")
      .setPosition(40,40)
      .setColorValue(0xffffffff)
      .setFont(createFont("Georgia",20))
      .moveTo(controlWindow)
      ;

  readmeText = cp5.addTextlabel("label")
               .setText("Select an under exposed photo.")
               .setPosition(40,80)
               .setColorValue(0xffffffff)
               .setFont(createFont("Georgia",18))
               .moveTo(controlWindow)
                ;

  cp5.addSlider("gamma_u")
     .setRange(0, 2)
     .setPosition(40, 140)
     .setSize(200, 29)
     .moveTo(controlWindow)
     ;

  cp5.addSlider("gamma_n")
     .setRange(0, 2)
     .setPosition(40, 180)
     .setSize(200, 29)
     .moveTo(controlWindow)
     ;

  cp5.addSlider("gamma_o")
     .setRange(0, 2)
     .setPosition(40, 220)
     .setSize(200, 29)
     .moveTo(controlWindow)
     ;

  cp5.addSlider("a_value")
     .setRange(0, 0.5)
     .setPosition(40, 300)
     .setSize(200, 29)
     .moveTo(controlWindow)
     ;

  cp5.addSlider("color_gain")
     .setRange(0, 5)
     .setPosition(40, 340)
     .setSize(200, 29)
     .moveTo(controlWindow)
     ;

  cp5.addSlider("scope_ratio")
     .setRange(0, 20)
     .setPosition(40, 380)
     .setSize(200, 29)
     .moveTo(controlWindow)
     ;

  cp5.addSlider("class_th")
     .setRange(0, 40)
     .setPosition(40, 420)
     .setSize(200, 29)
     .moveTo(controlWindow)
     ;

  cp5.addButton("Save Image")
     .setPosition(40,500)
     .setSize(100,39)
     .moveTo(controlWindow)
     ;

  cp5.addButton("Exit")
     .setPosition(160,500)
     .setSize(100,39)
     .moveTo(controlWindow)
     ;

  String imgPath = selectInput();
  img0 = loadImage(imgPath);
  readmeText.setText("Select a normal exposed photo.");

  imgPath = selectInput();
  img1 = loadImage(imgPath);

  readmeText.setText("Select an over exposed photo.");

  imgPath = selectInput();
  img2 = loadImage(imgPath);

  writeImg = createImage(img0.width, img0.height, RGB);

// long nt = System.nanoTime();

  MakeHDR();
  ToneMapping();

// long nt2 = System.nanoTime();

//  long a = nt2 -nt;
//  println("time=" +a );

  readmeText.setText("Completed.");

  if(img0.width > size_x || img0.height > size_y){
    float k_width = (float)img0.width / (float)size_x;
    float k_height = (float)img0.height / (float)size_y;
    float k_max;
    if(k_width > k_height){
      k_max = k_width;
    }else{
      k_max = k_height;
    }
    view_width = (int)(img0.width/k_max);
    view_height = (int)(img0.height/k_max);
  }else{
    view_width = img0.width;
    view_height = img0.height;
  }
}

public void controlEvent(ControlEvent theEvent) {
  if(theEvent.isFrom("color_gain")) {
    MakeHDR();
  }

  if(theEvent.isFrom("gamma_u")) {
    MakeHDR();
  }

  if(theEvent.isFrom("gamma_n")) {
    MakeHDR();
  }

  if(theEvent.isFrom("gamma_o")) {
    MakeHDR();
  }

  if(theEvent.isFrom("Save Image")) {
    String imgPath = selectOutput();
    writeImg.save(imgPath);
  }

  if(theEvent.isFrom("Exit")) {
    exit();
  }
}


void draw(){
  //  MakeHDR();
  ToneMapping();
  image(writeImg, 0, 0, view_width, view_height);
}

void MakeGamma(){
  for (int i = 0; i < 256; i++){
    lut_u[i] = 255*pow(((float)i/255),(1/gamma_u));
  }

  for (int i = 0; i < 256; i++){
    lut_n[i] = 255*pow(((float)i/255),(1/gamma_n));
  }

  for (int i = 0; i < 256; i++){
    lut_o[i] = 255*pow(((float)i/255),(1/gamma_o));
  }  
}

void MakeHDR(){
  MakeGamma();

  hdr_img_r = new int[img0.height*img0.width];
  hdr_img_g = new int[img0.height*img0.width];
  hdr_img_b = new int[img0.height*img0.width];

  img0.loadPixels();
  img1.loadPixels();
  img2.loadPixels();

  for(int i = 0; i < img0.width*img0.height; i++){
    color tmp_color0 = img0.pixels[i];
    color tmp_color1 = img1.pixels[i];
    color tmp_color2 = img2.pixels[i];

    hdr_img_r[i] =
      (int)((lut_u[(int)red(tmp_color0)] + lut_n[(int)red(tmp_color1)] + lut_o[(int)red(tmp_color2)])*color_gain/3);
    hdr_img_g[i] =
      (int)((lut_u[(int)green(tmp_color0)] + lut_n[(int)green(tmp_color1)] + lut_o[(int)green(tmp_color2)])*color_gain/3);
    hdr_img_b[i] =
      (int)((lut_u[(int)blue(tmp_color0)] + lut_n[(int)blue(tmp_color1)] + lut_o[(int)blue(tmp_color2)])*color_gain/3);

//    hdr_img_r[i] = hdr_img_r[i]/3*color_gain;
//    hdr_img_g[i] = hdr_img_g[i]/3*color_gain;
//    hdr_img_b[i] = hdr_img_b[i]/3*color_gain;
  }

  //debug-----
  /*
  for(int y = 0; y < img0.height; y++){
    for(int x = 0; x < img0.width; x++){
      int pos = x + y*img0.width;
      color tmp_color = color(hdr_img_r[pos], hdr_img_g[pos], hdr_img_b[pos]);
      set(x, y, tmp_color);
    }
  }
  */
  //----debug  
}

void ToneMapping(){
 long nt = millis();

  float lum_sum;
  int sum_numb;

  int scope = (int)(sqrt(img0.height*img0.width) * scope_ratio/100);
  int scope_speed = (int)(scope * scope_speed_ratio/100)+1;
  int average_speed = (int)(sqrt(img0.height*img0.width) * average_speed_ratio/100);

  // debug
//  println("scope= " + scope);
//  println("scope_speed= " + scope_speed);
//  println("average_speede= " + average_speed);

  //ToneMapping----
  int tmp = average_speed;
  float lum_sum_w = 0;

  int[] lum = new int[img0.height*img0.width];
  float[] lum_local = new float[img0.height*img0.width];
//  int[] lum_local = new int[img0.height*img0.width];
  int[] lum_class = new int[img0.height*img0.width];
  int[] u = new int[img0.height*img0.width];
  int[] v = new int[img0.height*img0.width];

  for(int y = 0; y < img0.height; y++){
    for(int x = 0; x < img0.width; x++){
      int pos = x + y*img0.width;
      lum[pos] = (307*hdr_img_r[pos] + 604*hdr_img_g[pos] + 113*hdr_img_b[pos])  >> 10;
      lum_local[pos] = log((float)(lum[pos]) / 256 + delta);
//      lum_local[pos] = (int)(log((float)(lum[pos]) / 256 + delta));

      u[pos] = (-174*hdr_img_r[pos] - 338*hdr_img_g[pos] + 512*hdr_img_b[pos]) >> 10;
      v[pos] = (512*hdr_img_r[pos] -430*hdr_img_g[pos] - 82*hdr_img_b[pos]) >> 10;
    }
  }
  
  int max_lum = (int)max(lum);
  for(int y = 0; y < img0.height; y++){
    for(int x = 0; x < img0.width; x++){
      int pos = x + y*img0.width;
      lum_class[pos] = (int)(float(lum[pos])/((max_lum+1)/max_lum_class));
    }
  }

  for(int y = 0; y < img0.height; y++){
    tmp = average_speed;
    for(int x = 0; x < img0.width; x++){
      int pos = x + y*img0.width;
      lum_sum = 0;
      sum_numb = 0;
      tmp++;
      if(tmp > average_speed){
        tmp = 0;
        for(int y_2 = y-scope; y_2 < y+scope; y_2 += scope_speed){
          for(int x_2 = x-scope; x_2 < x+scope; x_2 += scope_speed){
            if(y_2 >= 0 && y_2 < img0.height && x_2 >=0 && x_2 < img0.width){
                int pos_2 = x_2 + y_2*img0.width;
                if(abs(lum_class[pos] - lum_class[pos_2]) < class_th){
                  sum_numb++;
                  lum_sum += lum_local[pos_2];
              }
            }
          }
        }
        lum_sum_w = exp(lum_sum/(float)sum_numb);
      }

      float lum_w = lum[pos]/lum_sum_w*a_value;

      int r = (int)(1024*lum_w + 1433*v[pos]) >> 10;
      int g = (int)(1024*lum_w -348*u[pos] -727*v[pos]) >> 10;
      int b = (int)(1024*lum_w + 1812*u[pos]) >> 10;
      
      writeImg.pixels[pos] = color(r,g,b);
    }
  }
  writeImg.updatePixels();

  long nt2 = millis();

  long a = nt2 -nt;
  println("time=" +a );


}

