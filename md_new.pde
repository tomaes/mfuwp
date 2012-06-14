/* 
,-----------------------------------------------------------------------------
' 
'   music for underwater people  
'
'   an interactive "musicdisk" player interface
'   for the EP of the same name.
' 
'   written in Processing in Dec.2008/Jan.2009
'   (slightly modified and released in May 2012)
' 
'   music, graphics and this interface code 
'   by Thomas Gruetzmacher (http://tomaes.32x.de)
'
'   this source code is licenced under Creative Commons (CC-BY) 
'   http://creativecommons.org/licenses/by/3.0/
'----------------------------------------------------------------------------- 
*/

// ---------------------------------------------------------------------------
//   I. imports, variables, classes ...  
// ---------------------------------------------------------------------------
import ddf.minim.*;
import processing.opengl.*;
import codeanticode.glgraphics.*;

GLGraphicsOffScreen osb;
AudioPlayer player;
Minim minim;

// ---------------------------------------------------------------------------
PImage    miniLogo, frame;
PImage[]  sprites;
PFont     font, font2;

String[]  song = new String[10]; 

color[][] colscheme = new color[8][2];
color     bgColor;

Boolean   slowCPUMode = false, noSound = false;

int       colschemeSelected = -1, destColscheme; 
int       songSelected      = -1, songPlaying;
int       baseOffsetY       = 30, offsetY;

int       oldSong = 0, songsPlayed = 0, fxFadeCyclesOut = 1000, fxFadeCyclesIn = 10000;

int       fontHeightCredits = 11, fontHeightDefault = 16;

int       volume = 0;
int       rTime  = 0;

// ---------------------------------------------------------------------------
class CCreature 
{ 
  private int depth, x, type, anim1, anim2, animDelay;

  CCreature( int _depth, int _x, int _type, int _anim1, int _anim2, int _animDelay ) 
  { 
    x = _x; 
    depth = _depth; 
    type  = _type;
    anim1 = _anim1;
    anim2 = _anim2;
    animDelay = _animDelay;
  }    
}

ArrayList creatures = new ArrayList();

CCreature dummyCreature = new CCreature( 0,0,0, 0,0,0 );

// ---------------------------------------------------------------------------
//   II. setups  
// ---------------------------------------------------------------------------
void setup()
{

  // load cfg file and setup render window
  int initWidth = 800, initHeight = 300;
  int renderOption = 0;
  String[] cfgFile = loadStrings("config.txt");

  if ( cfgFile != null )
  {
    cfgFile = trim( cfgFile);

    for( int i = 0; i < cfgFile.length; i++ )
    {
      //if ( match( cfgFile[i], "J2D"  ) != null  ) renderOption = 0;
      //if ( match( cfgFile[i], "P2D"  ) != null  ) renderOption = 1;
      //if ( match( cfgFile[i], "OGL1" ) != null  ) renderOption = 2;
      //if ( match( cfgFile[i], "OGL2" ) != null  ) renderOption = 3;
      //if ( match( cfgFile[i], "P3D"  ) != null  ) renderOption = 4;
      if ( match( cfgFile[i], "MUTE" ) != null  ) noSound = true;   
      
      if ( match( cfgFile[i], "BIG"  ) != null  ) 
      { 
        initWidth  = 850; 
        initHeight = 350; 
      }       
      if ( match( cfgFile[i], "SMALL") != null  ) 
      { 
        initWidth  = 650;  
        initHeight = 300; 
      }   
      if ( match( cfgFile[i], "MED"  ) != null  ) 
      { 
        initWidth  = 800;  
        initHeight = 300; 
      }   
      if ( match( cfgFile[i], "SQR"  ) != null  ) 
      { 
        initWidth  = 450;  
        initHeight = 450; 
      }          
    }
  }
  else
  {
    println("Cannot find config.txt!");
  }

/*
  switch( renderOption )
  {
    case 0:  
      size( initWidth, initHeight, JAVA2D );
      println("using JAVA2D renderer");
      smooth();
      break;
    case 1:  
      size( initWidth, initHeight, P2D );        
      println("using P2D renderer");
      smooth();
      break;
    case 2:  
      size( initWidth, initHeight, OPENGL );
      hint( ENABLE_OPENGL_2X_SMOOTH );     
      //hint( DISABLE_DEPTH_TEST );
      //smooth();
      println("using OPENGL renderer, 2xSMOOTH");
      break;
    case 3:  
      size( initWidth, initHeight, OPENGL );
      hint( ENABLE_OPENGL_4X_SMOOTH );
      println("using OPENGL renderer, 4xSMOOTH");
      break;
    case 4:
      size( initWidth, initHeight, GLConstants.GLGRAPHICS );
      osb = new GLGraphicsOffScreen( this, width, height, true, 4 );
      println("using GLGRAPHICS renderer");
      break;  
  }
*/  
  // 4x AA please!
  size( initWidth, initHeight, GLConstants.GLGRAPHICS );
  osb = new GLGraphicsOffScreen( this, width, height, true, 4 );  

  // fast enough really
  frameRate( 20 );

  // load & init sprites
  sprites    = new PImage[8];
  sprites[0] = new PImage(); 
  sprites[0] = loadImage("bubble1.png");
  sprites[1] = new PImage();  
  sprites[1] = loadImage("bubble2.png");
  sprites[2] = new PImage(); 
  sprites[2] = loadImage("fish1.png");
  sprites[3] = new PImage(); 
  sprites[3] = loadImage("fish1002.png");
  sprites[4] = new PImage(); 
  sprites[4] = loadImage("fish2.png");
  sprites[5] = new PImage(); 
  sprites[5] = loadImage("fish2002.png");
  sprites[6] = new PImage(); 
  sprites[6] = loadImage("jellyfish.png");
  sprites[7] = new PImage(); 
  sprites[7] = loadImage("jellyfish002.png");

  miniLogo = new PImage();
  miniLogo = loadImage("splash.png");
  frame    = new PImage();  
  frame    = loadImage("frame.png");
  

  //   ( int _depth, int _x, int _type, int _anim1, int _anim2, int _animSpeed ) 
  // init bubbles
  for( int i = 0; i < 200; i++ )
  {
    creatures.add( new CCreature(       i * 10, int( random( -width/2, width ) ), 0,  0,0,10 )  );
    creatures.add( new CCreature(1000 + i * 10, int( random( -width/2, width ) ), 1,  1,1,10 )  );
  }
  // init fishes
  for( int i = 0; i < 300; i++ )
  {
    creatures.add( new CCreature(500  + i * 10, int( random( 0, width * 2 ) ), 2, 2,3,5  )  ); // fast
    creatures.add( new CCreature(1500 + i * 50, int( random( 0, width * 2 ) ), 3, 4,5,10 )  );
  }
  // init jellyfish
  for( int i = 0; i < 250; i++ )
  {
    creatures.add( new CCreature(2500 + i * 10, int( random( -width/2, width ) ), 4,  6,7,10 )  ); // slower
  }

  minim = new Minim( this );

  font  = createFont("GARA.TTF", fontHeightDefault ); // GARA.TTF: Garamond Font
  font2 = createFont("GARA.TTF", fontHeightCredits ); // small version

  textFont( font, fontHeightDefault );   
  noStroke();

  // playlist
  song[0] = "Overture Below Sea Level"; 
  song[1] = "Kelp Forrest";     
  song[2] = "Towards Shiny Coral Reefs";
  song[3] = "Streamline";               
  song[4] = "Sea Monster";      
  song[5] = "Plankton Groove";
  song[6] = "Deep Blue End";            
  song[7] = "Dolphin Language"; 
  song[8] = "The Lonesome Swordfish"; 
  song[9] = "Bonus: Jellyfish Armada";

  // init colour schemes
  colscheme[0][0] = color( 120, 160, 120 ); colscheme[0][1] = color( 180, 240, 120 ); 
  colscheme[1][0] = color( 210,  60,  60 ); colscheme[1][1] = color( 80,  130, 200 );
  colscheme[2][0] = color( 120, 130, 160 ); colscheme[2][1] = color( 120, 160, 120 );
  colscheme[3][0] = color( 100, 200, 150 ); colscheme[3][1] = color( 120, 190, 120 );
  colscheme[4][0] = color( 120, 160, 200 ); colscheme[4][1] = color( 220, 160, 120 ); 
  colscheme[5][0] = color( 170, 170, 170 ); colscheme[5][1] = color( 160, 160, 120 );
  colscheme[6][0] = color( 220, 240, 210 ); colscheme[6][1] = color( 240, 230, 110 ); 
  colscheme[7][0] = color(  90, 120, 120 ); colscheme[7][1] = color( 120, 160, 160 );

  bgColor = colscheme[0][0];
    
  playSong( 0 );
    
}

// ---------------------------------------------------------------------------
//   III. helper functions  
// ---------------------------------------------------------------------------
void playSong( int _nr )
{
  println( "tomaes0" + str( _nr+1 ) + ".mp3 playing..." );

  if ( songsPlayed > 0 ) player.close();

  player = minim.loadFile( "tomaes0" + str( _nr+1 ) + ".mp3", 4096 );
  
  // mute if need be
  if ( noSound ) player.setGain( -80 ); /* -80..6 */ else player.setGain( volume ); 

  player.play();
  
  // we're only interested in the first few plays
  if ( songsPlayed < 2 ) songsPlayed++;
  
}

void playNextSong()
{

  if (songPlaying < 9) 
  { 
    playSong( ++songPlaying ); 
  } 
  else 
  { 
    songPlaying = 0; 
    playSong( 0 ); 
  }

}

// ---------------------------------------------------------------------------
//   IV.  mouse clicks ( song & colour scheme menus ) & key presses
// ---------------------------------------------------------------------------
void mousePressed()
{

  if ( (songSelected >= 0) && (songSelected != songPlaying) )
  {
    oldSong     = songPlaying;    
    songPlaying = songSelected;
    playSong( songPlaying );
  }

  if ( (colschemeSelected >= 0) && (destColscheme != colschemeSelected) )
  {
    destColscheme = colschemeSelected;
    bgColor = color( red(bgColor)/3, blue(bgColor)/3, green(bgColor)/3 );
  }

}

void keyPressed()
{
  if ( key == 's' || key == 'S' ) saveFrame("mfuwp-interface-screenshot-####.png");
  
  if ( key == 'b' || key == 'B' ) slowCPUMode = !slowCPUMode; 
  
  //if ( key == 'n' || key == 'N' ) smooth();
  //if ( key == 'm' || key == 'M' ) noSmooth();

  if ( key == 'x' || key == 'X' ) 
  { 
     if ( noSound ) 
    {  
       player.setGain( volume ); 
       noSound = false; 
    }
    else
    {  
       player.setGain( -80 ); 
       noSound = true; 
    }
  }
  
  if ( key == CODED )
  {
      if ( keyCode == UP ) 
      { 
        oldSong = songPlaying;
        if (songPlaying > 0) playSong( --songPlaying ); else playSong( songPlaying = 9 ); 
      }
      if ( keyCode == DOWN ) 
      {
        oldSong = songPlaying;
        if (songPlaying < 9) playSong( ++songPlaying ); else playSong( songPlaying = 0 ); 
      }
      if ( keyCode == LEFT )
      {
        if (destColscheme > 0) destColscheme--; else destColscheme = 7; 
      }
      if ( keyCode == RIGHT )
      {
        if (destColscheme < 7) destColscheme++; else destColscheme = 0; 
      }
  }
  
  if ( key == '+' && volume <   0 ) 
  {  
     volume++; 
     if ( !noSound ) player.setGain( volume );
  }
  if ( key == '-' && volume > -55 ) 
  { 
     volume--; 
     if ( !noSound ) player.setGain( volume ); 
  }

  
  if ( key >= '0' && key <= '9' )
  {
    
    oldSong = songPlaying;
    
    if (key == '0')
     playSong( songPlaying = 9 ); 
    else 
     playSong( songPlaying = key - 49 );     
  } 
  
} 

// ---------------------------------------------------------------------------
//   V. vfx
// ---------------------------------------------------------------------------
float _mouseXPot = 0.0f, _mouseYPot = 0.0f;
int   _fxPosX = width/2, _fxPosY = height/2;

void fx_Spiral()
{

  int x, y, sizeX, sizeY, elements, skipLines;
  float freq1, freq2, time1, time2, amp1, amp2, amp3, time3 = 0.0f, freq3 = 0.0f, amp4 = 0.0f;
  float shrink = 1.0f, deflate = 1.0f;
  int div1, mod1, mul1;
  int type = songPlaying;
  
  Boolean noLines = false;
  float   _t      = (float)rTime / 3.0f;

  // calc transition shrinkage for fx fade-out/in & adjust type, if it's not the first song
  if ( (player.position() < fxFadeCyclesOut) && (songsPlayed > 1) )
  {
     shrink  = 1.0f - (float)player.position() * 0.001f;
     deflate = 1.0f + (float)player.position() * 0.1f;
     type    = oldSong;
     noLines = true; 
  }
  else if ( player.position() < (fxFadeCyclesIn + fxFadeCyclesOut) )
  {
     shrink = (float)( player.position() - fxFadeCyclesOut ) * 0.0001f;     
     type   = songPlaying;
  }
  

  switch ( type )
  {
    case 0:
      elements = 300;
      freq1 = 0.5f;  
      freq2 = 0.005f;
      time1 = 0.06f; 
      time2 = 0.05f;
      amp1  = 10.0f; 
      amp2  = 14.0f; 
      amp3  = 0.2f;    
      div1  = 100; mod1  = 2; mul1 = 30;
      skipLines = 4;
      break;          
    case 1:
      elements = 250;
      freq1 = 4.0f;  
      freq2 = 0.02f;
      time1 = 0.2f;  
      time2 = 0.1f;
      amp1  = 1.0f; 
      amp2  = 12.0f; 
      amp3 = 0.1f;    
      div1  = 1; mod1  = 1; mul1 = 0;
      skipLines = 10;
      break;
    case 2:
      elements = 250;
      freq1 = 0.04f; 
      freq2 = 0.01f;
      time1 = 0.1f;  
      time2 = 0.03f;
      amp1  = 10.0f; 
      amp2  = 30.0f; 
      amp3  = 0.1f;    
      div1  = 100; mod1  = 2; mul1 = 10;
      skipLines = 10;
      break;
    case 3:
      elements = 200;
      freq1 = 0.1f;  
      freq2 = 0.05f;
      time1 = 0.4f;  
      time2 = 0.1f;
      amp1  = 10.0f; 
      amp2  = 20.0f; 
      amp3  = 0.2f;    
      div1  = 100; mod1  = 2; mul1 = 6;
      skipLines = 200;
      break;
    case 4:
      elements = 160;
      freq1 = 0.2f;  
      freq2 = 0.01f;
      time1 = 0.02f;  
      time2 = 0.01f;
      amp1  = 10.0f; 
      amp2  = 30.0f; 
      amp3 = 0.2f;
      div1  = 50; mod1  = 2; mul1 = 2;
      skipLines = 160;
      break;
    case 5:
      elements = 400;
      freq1 = 11.05f;  
      freq2 = 0.01f;
      time1 = 0.1f;  
      time2 = 0.1f;
      amp1  = 10.0f; 
      amp2  = 10.0f; 
      amp3 = 0.2f;
      div1  = 100; mod1  = 2; mul1 = 30;
      skipLines = 4;
      break;
    case 6:
      elements = 270;
      freq1 = 0.08f;  
      freq2 = 0.01f;
      time1 = 0.03f;  
      time2 = 0.06f;
      amp1  = 10.0f; 
      amp2  = 50.0f; 
      amp3  = 0.1f;
      div1  = 2; mod1  = 2; mul1 = 0;
      skipLines = 4;
      break;
    case 7:
      elements = 300;
      freq1 = 0.4f;  
      freq2 = 0.2f;
      time1 = 0.01f;  
      time2 = 0.01f;
      amp1  = 10.0f; 
      amp2  = 5.0f; 
      amp3  = 0.5f;
      skipLines = 1;
      time3 = 0.1f; 
      freq3 = 4.0f; 
      amp4  = 20.0f;
      div1  = 100; mod1  = 2; mul1 = 30;
      break;
    case 8:
      elements = 360;
      freq1 = 0.01f + sin( _t * 0.002f ) * 0.06f; 
      freq2 = 0.1f;
      time1 = 0.02f; 
      time2 = 0.05f;
      amp1  = 0.6f;  
      amp2  = 2.0f; 
      amp3  = 0.05f;    
      div1  = 50; mod1  = 2; mul1 = 20;
      skipLines = 12;
      break;      
    default: // bonus track
      elements = 300;
      freq1 = 0.3f + sin( _t * 0.0025f ) * 0.05f; 
      freq2 = 0.1f + cos( _t * 0.0010f ) * 0.05f;
      time1 = 0.06f; 
      time2 = 0.05f;
      amp1  = abs( sin( _t * 0.05f ) * 0.5f ); 
      amp2  = 10.0f;  
      amp3  = 0.1f;    
      time3 = 0.1f; 
      freq3 = 0.02f; 
      amp4  = 10.0f;
      div1  = 100; mod1  = 2; mul1 = 30;
      skipLines = 4;
  }


  // fx positions
  _fxPosX += (mouseX - _fxPosX) / 10 + (int) ( sin( rTime * 0.05f ) * 10.0f  + sin( rTime * 0.01f + sin( rTime * 0.01f ) * 10.0f ) * 6.0f );
  _fxPosY += (mouseY - _fxPosY) / 10 + (int) ( cos( rTime * 0.05f ) * 10.0f  + cos( rTime * 0.01f + sin( rTime * 0.01f ) * 10.0f ) * 6.0f );

  int centerX = _fxPosX;
  int centerY = _fxPosY;


  // draw lines
  if ( !noLines )
  for( int i = 0; i < elements; i += skipLines )
  {
    x = centerX  + int( sin( _t*time1 + i*freq1 ) * (amp1 + (float)i + sin( _t*time3 + (float)i*freq3 )*amp4 ) * shrink );
    y = centerY  + int( cos( _t*time1 + i*freq1 ) * (amp1 + (float)i + cos( _t*time3 + (float)i*freq3 )*amp4 ) * shrink );

    osb.strokeWeight( abs( sin( (i*2 + _t * 0.5f)*0.03f ) * 20.0f ) ); 
    osb.stroke( 30 + red(bgColor) + (i%3)*10, 30 + green(bgColor) + (i%3)*10, 30 + blue(bgColor) + (i%3)*10, 150 );
    osb.line( x,y ,centerX, centerY );
  }

  // draw circles
  for( int i = 0; i < elements; i++ )
  {
    x = centerX + int( ( sin( _t*time1 + i*freq1 * deflate ) * (amp1 + i + sin( _t*time3 + i*freq3 )*amp4 ) + sin( (i*10.0f + _t * 0.5f)*0.1f ) * (float)( (i/div1)%mod1 * mul1) ) * shrink );
    y = centerY + int( ( cos( _t*time1 + i*freq1 * deflate ) * (amp1 + i + cos( _t*time3 + i*freq3 )*amp4 ) + cos( (i*10.0f + _t * 0.5f)*0.1f ) * (float)( (i/div1)%mod1 * mul1) ) * shrink );
    
    if ( (i/5)%2 == 0 )
    {
      if (deflate > 1.0f) osb.fill( colscheme[ destColscheme ][0] ); else osb.fill( colscheme[ destColscheme ][1], 255 - i*2 );  
    }
    else osb.noFill();

    sizeX = int( amp2 + 5 + sin( _t + i * (0.3f + sin( _t * time2 + i * freq2 ) * amp3)  ) * amp2);
    sizeY = sizeX;

    osb.strokeWeight( abs( 2.0f + sin( i * 0.1f + _t * 0.4f ) * 1.7f)  );

    osb.stroke( 255 - i/2, x, y );
    osb.ellipse( x, y, sizeX, sizeY );
    //rect( x, y, sizeX, sizeY );

    osb.stroke( red(bgColor)/2, green(bgColor)/2, 160 - mouseX / 5, 50+(i/100)%2*150 );
    osb.ellipse( x - 2, y - 2, sizeX + 6, sizeY + 6 );           
    //rect( x - 2, y - 2, sizeX + 6, sizeY + 6 );

    osb.noFill();
    osb.stroke( 250, 100 );
    osb.strokeWeight( 0.3f );
    osb.ellipse( x - 2, y - 2, sizeX, sizeY );           
    //rect( x - 2, y - 2, sizeX, sizeY );
  }
  
  
}

// ---------------------------------------------------------------------------
//   VI. main loop
// ---------------------------------------------------------------------------
void draw()
{
  
  // CHEAP, usually you'd want to deal with "millis()" here
  rTime++;
  
  
  osb.beginDraw();
    

  // colour scheme fades [TODO: for foreground aswell]
  if ( colscheme[ destColscheme ][0] != bgColor ) // envColor[0] for bg, envColor[1] for fg
  {
    int   changePace = 10; 
    float tR = red(bgColor), tG = green(bgColor), tB = blue(bgColor);

    if ( tR >   red( colscheme[destColscheme][0] )  ) tR -= changePace;   
    if ( tR <   red( colscheme[destColscheme][0] )  ) tR += changePace;   

    if ( tG > green( colscheme[destColscheme][0] )  ) tG -= changePace;   
    if ( tG < green( colscheme[destColscheme][0] )  ) tG += changePace;   

    if ( tB >  blue( colscheme[destColscheme][0] )  ) tB -= changePace;   
    if ( tB <  blue( colscheme[destColscheme][0] )  ) tB += changePace;  

    bgColor = color( tR, tG, tB );
  }  
  

  osb.background( bgColor );     
    
  if ( !slowCPUMode )
  {
    // draw bg animation
    stroke( red(bgColor)*1.05f, green(bgColor)*1.05f, blue(bgColor)*1.05f  );
    
    for( int i = 0; i < 400; i++ )
    {
      osb.strokeWeight( 3 );
      osb.stroke( red(bgColor)*1.05f, green(bgColor)*1.05f, blue(bgColor)*1.05f + i%2*40 );
      osb.fill( red(bgColor) * 1.1f - (i%2)*20.0f, green(bgColor) * 1.0f + (i%3)*20.0f, blue(bgColor) * 1.1f + (i%3)*10.0f );

      osb.ellipse( 20 + i * 2 + sin( rTime * 0.1f + i * 1.0f ) * 10, i%20 * 30 , 
                   20 + sin( rTime * 0.1f + i * 0.5f ) * 5, 4 + sin( rTime * 0.1f + i * 0.5f ) * 10 );
    }
    
  }


  // move and draw creatures
  for( int i = 0; i < creatures.size()-1 ; i++ ) 
  {

    switch ( ((CCreature)creatures.get(i)).type )
    {
      // bubbles
      case 0: 
        ((CCreature)creatures.get(i)).depth += sin( rTime * 0.2f + (float)i * 0.8f ) * 1.5f; 
        break;
      case 1: 
        ((CCreature)creatures.get(i)).depth += sin( rTime * 0.1f + (float)i * 1.0f ) * 1.0f; 
        break;
      // fish
      case 2: 
        ((CCreature)creatures.get(i)).x -= abs( sin( rTime * 0.04f + (float)i * 0.01f ) * 3.0f ); 
        if ( ((CCreature)creatures.get(i)).x < -width ) ((CCreature)creatures.get(i)).x = width * 2;
        break;
      case 3: 
        ((CCreature)creatures.get(i)).x -= abs( sin( rTime * 0.04f + (float)i * 0.04f ) * 3.0f ); 
        if ( ((CCreature)creatures.get(i)).x < -width ) ((CCreature)creatures.get(i)).x = width * 2;
        break;
      // jellyfish
      default: 
        ((CCreature)creatures.get(i)).depth += sin( rTime * 0.5f + (float)i * 0.4f ) * 4.0f;
    }

    dummyCreature = (CCreature)creatures.get(i);

    if ( (frameCount + mouseY) > (  dummyCreature.depth  ) )
    {
      if ( (frameCount/dummyCreature.animDelay)%2 == 0 )    
       osb.image( sprites[ dummyCreature.anim1 ], dummyCreature.x + mouseX, height - (rTime - dummyCreature.depth) - mouseY/2  ); 
      else 
       osb.image( sprites[ dummyCreature.anim2 ], dummyCreature.x + mouseX, height - (rTime - dummyCreature.depth) - mouseY/2  );        
    }
    
  } //for


  offsetY = baseOffsetY; 

  int offsetYsin = int( sin( rTime * 0.01f ) * 20 + sin( rTime * 0.02f ) * 120 ); 

  osb.noStroke();  

  // draw 'depth meter'  
  for( int i = 0; i < 5; i +=2 )
  {
    osb.fill( color(  red(bgColor)*0.7, green(bgColor)*0.7, blue(bgColor)*0.7  ) );
    osb.rect( mouseX/2 + i * 100 , 0, 1, height*2 - 10 );
  }

  osb.textSize( fontHeightCredits );

  for( int i = 0; i < 3; i++ )
  {
    osb.text( "-- " + str( rTime + (rTime + mouseY) % height ) + "m", mouseX/2  + i * 200, height - (rTime + mouseY) % height );  
  }

  // .oO°Oo.oO°
  fx_Spiral();  

  osb.fill( 0 );

  // bg frame
  osb.image( frame, 0, 0, width, height );
  // bg Logo
  osb.image( miniLogo, width - 155, -4 ); 
  
  
  // song ended? new one!
  if ( !player.isPlaying() ) playNextSong();
  
  // default: no song selected
  songSelected = -1;


  // draw song selection menu
  for( int i = 0; i < 10; i++ )
  {
    osb.fill( bgColor );

    if ( (mouseX > 10+i*20) && (mouseX < 28+i*20) && (mouseY > height-80) && (mouseY < height-80+15) )
    {
      osb.stroke( 100 + int( sin( rTime * 0.4f) * 60 ) );
      cursor( HAND );
      osb.strokeWeight( 2.0f );
      songSelected = i;
    }
    else
    {
      osb.strokeWeight( 0.2f );
      osb.stroke( 0 );
    }

    if ( i == songPlaying ) 
    {
      osb.stroke( 200 ); 
      osb.strokeWeight( 1.5f );
      osb.fill( 200 +  + int( sin( rTime * 0.1f) * 40.0f ) );
    }

    osb.rect( 10 + i*20, height - 80, 18, 15 );
  }

  // reset cursor in arbitrary intervals 
  if ( frameCount%5 == 0 ) cursor( ARROW );


  // render some song info
  osb.textFont( font, fontHeightDefault );
  osb.textSize( fontHeightDefault );  

  osb.fill( red(bgColor)+40, green(bgColor)+40, blue(bgColor)+40 );
  osb.text( song[ songPlaying ] + " (" + str(player.position()/1000) + "s)" , 10, height-85 );
  osb.fill( 20 );
  osb.text( song[ songPlaying ] + " (" + str(player.position()/1000) + "s)" , 9, height-85 );

  
  osb.fill( red(bgColor)+30, green(bgColor)+30, blue(bgColor)+30 );
  osb.textFont( font2, fontHeightCredits );
  osb.textSize( fontHeightCredits );
  osb.text("music for underwater people, 2oo9/12 musicdisk edition", 11, height-45);
  osb.text("music, interface design and programming by tomaes", 11, height-35);
 
  osb.fill( 0 );  
  osb.text("music for underwater people, 2oo9/12 musicdisk edition", 10, height-45);
  osb.text("music, interface design and programming by tomaes", 10, height-35);


  colschemeSelected = -1;


  // draw colour scheme menu
  for( int i = 0; i < 8; i++ )
  {
    osb.fill( colscheme[i][0] );

    if ( (mouseX > 10+i*25) && (mouseX < 30+i*25) && (mouseY > height-20) && (mouseY < height-10) )
    {
      osb.stroke( 100 + int( sin( frameCount * 0.4f) * 60 ) );
      cursor( HAND );
      osb.strokeWeight( 2.0f );
      colschemeSelected = i;
    }
    else
    {
      osb.strokeWeight( 1.0f );
      osb.stroke( 0 );
    }

    if ( i == destColscheme ) 
    {
      osb.stroke( 200 ); 
      osb.strokeWeight( 1.5f );
    }

    osb.rect( 10 + i*25, height - 20, 20, 10 );
  }

  // volume control
    if ( (mouseX > width-20) && (mouseX < width-10) && (mouseY > height-50) && (mouseY < height-20) )
    {
      osb.stroke( 100 + int( sin( frameCount * 0.4f) * 60 ) );
      cursor( HAND );
      osb.strokeWeight( 2.0f );
      volume = -( mouseY - (height - 49) ) * 2;
      if ( !noSound ) player.setGain( volume );
      println("volume set to: " + volume );
    }
    else
    {
      osb.stroke( 160 );
    }

  // slider
  osb.strokeWeight( 0.0f );
  if (noSound) osb.fill( 100, 30, 0 ); else osb.fill( color(200,250,200) );
  osb.rect( width-18, height - 50 -(volume/2), 6, 4 );
  // backdrop
  osb.strokeWeight( 2.0f );
  osb.fill( 0, 50 );
  osb.rect( width-20, height-50, 10, 32 );
  
  osb.endDraw();

  // blend buffer
  tint(255,255);
  image(osb.getTexture(),0,0, width, height);

}

// ---------------------------------------------------------------------------
//   VII. destruct minim properly
// ---------------------------------------------------------------------------
void stop()
{  
  player.close(); 
  minim.stop(); 
  super.stop();
}
