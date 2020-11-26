//User Interface
import g4p_controls.*;
boolean pause = false;

//Settings
int n = 250;                //Cell grid size (Recommended: 250)
float padding = 50;         //Border
float blinks = 20;          //Frames per second

//Probabilities are in percentages ie. 0.03 = 3%, therefore max value of 1 (100%)
float bearSpawn = 0.03;     //Probability of bear spawing on ice initially(Recommended: 0.03)
float iceMelt = 0.1;        //Probability of ice melting when there is water around (Recommended: 0.1)
float drown = 0.3;          //Probability of polar bear drowning if in water (Recommended: 0.3)
float migration = 0.05;     //Probability of polar bear drowning while swimming (Recommended: 0.05)

//Declaring Variables
String[][] cell;
String[][] newcell;
int[][] xInc;
int[][] yInc;
float cellSize;
int iceChunks = 4;

//Setup
void setup() {
  //Grid
  size(800, 800, P3D);
  
  //Initial values
  reset();
  
  //UI
  createGUI(); 
}

//reset if changing values
void reset() {
  //Grid
  cellSize = (width-2*padding)/n;
  frameRate(blinks);

  //Fill arrays
  cell = new String[n][n];
  newcell = new String[n][n];
  xInc = new int[n][n];
  yInc = new int[n][n];
  
  //Get start position
  setInitial();
}

//Loop
void draw(){
  if (!pause){
    //Gray background and prevent outlines on cells
    noStroke();
    background(200, 200, 200);
    
    //Starting Y value slightly down to create border
    float y = padding;
    
    //Drawing for all row and column
    for(int i=0; i<n; i++) {
      for(int j=0; j<n; j++) {  
        //x value increments
        float x = padding + j*cellSize;
        
        //Water cell
        if (cell[i][j].equals("w")){
          //Randomize colour of water to create water movement effect
          int colour = round(random(0, 2));
          if (colour == 0)
            fill(80, 150, 255);
          else if (colour == 1)
            fill(40, 150, 255);
          else
            fill(0, 150, 255);
        }
        //Ice cell
        else if (cell[i][j].equals("i") || cell[i][j].equals("ic"))
          fill(255);
        
        //Polar bear cell
        else
          fill(200, 200, 200);
        
        //Draw cell
        rect(x, y, cellSize, cellSize);
      }
      
      //Increasing y-value to go to next row
      y += cellSize;
    }
    //Create next generation
    nextGen();
    
    //Replace old gen with new
    replace();
  }
}

//Beginning cell configurations
void setInitial() {
  //Start all cells as water
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < n; j++) {
      cell[i][j] = "w";
    }
  }
  
  //Create ice core
  setIceCores();
}

//Ice cells cores
void setIceCores(){
  //Randomly Select Ice Cores
  for (int i = 0; i < iceChunks/2; i++){
    for (int j = 0; j < iceChunks/2; j++){
      //Select it within quadrants
      int q = round(random(n/(1.5)*i, n/3+n/(1.5)*i-1));
      int w = round(random(n/(1.5)*j, n/3+n/(1.5)*j-1));
      cell[q][w] = "ic";
      
      for (int a = -n/10; a < n/10; a++){
        for (int b  = -n/10; b < n/10; b++){
          //If on edge, and geos off screen it will just continue
          try{
            cell[q + a][w + b] = "i";
          }
          catch(Exception e){}
        }
      }
      
      //Expand the ice cells from core
      buildIce();
    }
  }
}

//Exapnding the ice cores
void buildIce(){
  for (int i = 0; i < n; i++){
    for (int j = 0; j < n; j++){
      //Chance to expand ice chunk
      float chance = random(0,1);
      if (chance > 0.95){
        if (cell[i][j].equals("i")){
          //Create random size blocks around ice to create natural ice chunk 
          int expand = round(random(0, sqrt(n/6)));
          for (int a = -expand; a < expand; a++){
            for (int b  = -expand; b < expand; b++){
              try{
                cell[i + a][j + b] = "i";
              }
              catch(Exception e){}
            }
          }
        }
      }
    }
  }
  
  //Place polar bears
  polar();
}

//Creating the next generation
void nextGen(){
  for (int i = 0; i < n; i++){
    for (int j = 0; j < n; j++){
      //Checks the neighbour cells
      int bear = checkOutside(i, j);
      int water = checkWater(i, j);
      
      //If migrating bear
      if (cell[i][j].equals("m")){
        //If it has found a low population area it will turn into a polar bear
        if (bear < 4 && water < 3)
          newcell[i][j] = "p";

        //Migrating in water can lead to drowning  
        else if (water > 8){
          //Chance to drown
          float prob = random(0, 1);
          if (prob >= (1-migration))
            newcell[i][j] = "w";
          //Increment the x and y cell values for the migrating polar bears while in water
          else{
            try{
              newcell[i+(xInc[i][j])][j+(yInc[i][j])] = "m";
              xInc[i+(xInc[i][j])][j+(yInc[i][j])] = xInc[i][j];
              yInc[i+(xInc[i][j])][j+(yInc[i][j])] = yInc[i][j];
              newcell[i][j] = "w";
            }
            catch(Exception e){
              newcell[i][j] = "w";
            }
          }
        }
        
        //Increment the x and y cell values for the migrating polar bears while on ice
        else{
          try{
            newcell[i+(xInc[i][j])][j+(yInc[i][j])] = "m";
            xInc[i+(xInc[i][j])][j+(yInc[i][j])] = xInc[i][j];
            yInc[i+(xInc[i][j])][j+(yInc[i][j])] = yInc[i][j];
            newcell[i][j] = "i";
          }
          catch(Exception e){
            newcell[i][j] = "i";
          }
        }
      }
      
      //If ice cell
      else if (cell[i][j].equals("i")){
        //If lot's of water around ice, it will have a chance to turn into water, shrinking ice chunks
        if (water > 7){
          //Probability of ice melting
          float prob = random(0, 1);
          if (prob >= (1-iceMelt))
            newcell[i][j] = "w";
          else
            newcell[i][j] = cell[i][j];
        }

        //If there are more than three bears and less than 6 bears on ice, they can breed
        else if (bear == 4 && water == 0) {
          newcell[i][j] = "p";
        }
        
        else
          newcell[i][j] = cell[i][j];
      }
      
      //If polar bear
      else if (cell[i][j].equals("p")){
        //If in chance to drown
        if (water > 21){
          float prob = random(0, 1);
          //Chance to drown
          if (prob >= (1-drown))
            newcell[i][j] = "w";
          else
            newcell[i][j] = cell[i][j];
        }
        
        //If more than 4 bears, the bear will start migrating
        else if (bear > 4){
          xInc[i][j] = round(random(-5, 5));
          yInc[i][j] = round(random(-5, 5));
          newcell[i][j] = "m";
        }
        
        else
          newcell[i][j] = cell[i][j];
      }
      
      else
        newcell[i][j] = cell[i][j];
    }   
  }
}

//Generate polar bears on ice
void polar(){
  for (int i = 0; i < n; i++){
    for (int j = 0; j < n; j++){
      //If on ice, chance to become polar bear
      if (cell[i][j].equals("i")){ 
        //Percentage chance of spawning a bear
        float chance = random(0,1);
        if (chance > (1 - bearSpawn)){
          cell[i][j] = "p";
        }
      }
    }
  }
}

//Checks how many bears there are in a 5x5 area
int checkOutside(int i, int j){
  //Start with zero bears around
  int bears = 0;
  for (int a = -2; a < 3; a++){
    for (int b  = -2; b < 3; b++){
      //Checking for polar bears and catching if array index out of bounds
      try{
        if (cell[i + a][j + b].equals("p"))
          bears++;
      }
      catch (Exception e){}
    }
  }
  return bears;
}

//Checks how many water cells there are in a 5x5 area
int checkWater(int i, int j){
  int water = 0;
  for (int a = -2; a < 3; a++){
    for (int b  = -2; b < 3; b++){
      //Checking for water cells and catching if array index out of bounds
      try{
        if (cell[i + a][j + b].equals("w"))
          water++;
      }
      catch (Exception e){}
    }
  }
  return water;
}

//Replace the old generation cells with new generation
void replace(){
  for (int i = 0; i < n; i++){
    for (int j = 0; j < n; j++){
      cell[i][j] = newcell[i][j];
    }
  }
}
