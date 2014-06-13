import java.awt.Image;
import java.util.Vector;
import processing.opengl.*;
// Processing & TUIO import
import processing.core.*;
import TUIO.*;
import java.util.ArrayList;

TuioClient client = null;

//
JSONArray data = new JSONArray();
ArrayList<PImage> Images = new ArrayList<PImage>();

PImage img;
// Window Size
int SCREEN_SIZE_X = 900;
int SCREEN_SIZE_Y = 900;
int FULL_SIZE_MODE = 1;

// Image Position & Size & Angle
float imagePositionX = 0.0F;
float imagePositionY = 0.0F;
float imageWidth = 250.0F;
float imageHeight = 250.0F;
float imageRotate = 0.0F;
Boolean imageIsDragging = false;
float imageDragStartPositionX = 0.0F;
float imageDragStartPositionY = 0.0F;

ArrayList<Vector<TuioCursor>> gestureLog = new ArrayList();

// 1. Setup
public void setup() {
  // 0. Set Window
  if(FULL_SIZE_MODE==1){
    SCREEN_SIZE_X = displayWidth;
    SCREEN_SIZE_Y = displayHeight;   
  }
  size(SCREEN_SIZE_X, SCREEN_SIZE_Y,OPENGL);

  // 1. Create TuioClient
  client = new TuioClient();
  client.connect();

  // 2. Load Image
  initData();
  initCoverPosition();
println(data);  
}

// 2. draw
public void draw() {
  // set Background color
  background(100);
  // call multi-touch values and update
  //updateImageData();
  drawAlbums();
  //drawAlbumContents();
  updateGestureLog();
  TuioCursor tapCursor = getTap();
  TuioCursor dragstartCursor = getDragstart();
  TuioCursor dragmoveCursor = getDragmoving();
  TuioCursor dragendCursor = getDragend();

  if (tapCursor != null) { 
    tapHandler(tapCursor);
  }  
  if (dragstartCursor != null) { 
    dragstartHandler(dragstartCursor);
  }
  if (dragmoveCursor != null) { 
    dragmoveHandler(dragmoveCursor);
  }
  if (dragendCursor != null) { 
    dragendHandler(dragendCursor);
  }
}

public void updateGestureLog() {
  if (gestureLog.size() > 300) {
    gestureLog.remove(0);
  } 
  gestureLog.add(client.getTuioCursors());
}

public boolean isCursorExist(int cursorID,  Vector<TuioCursor> cursors) {
  for(TuioCursor cursor : cursors) {
    if(cursorID==cursor.getCursorID()){
      return true; 
    }
  }
  return false;
}

public TuioCursor getTap() { // 1: tap(0->1->0)
  int count1 = 0;
  // tap recognizer
  // check tap(0->1->0) pattern for before last log.
  int sizeOfGestureLog = gestureLog.size();
  if(sizeOfGestureLog > 100) {
    int numberOfCursor = gestureLog.get(sizeOfGestureLog-2).size();
    Vector<TuioCursor> beforeLastCursors = gestureLog.get(sizeOfGestureLog-2);
    Vector<TuioCursor> lastCursors = gestureLog.get(sizeOfGestureLog-1);
    //println(numberOfCursor);
    for(int i=0;i<numberOfCursor;i++){
      TuioCursor cursor = beforeLastCursors.get(i);
      if ((sizeOfGestureLog > 100)&&(isCursorExist(cursor.getCursorID(), lastCursors) == false)) {
      // there is no matched last cursors by cursorId
        for (int j=sizeOfGestureLog-3;j>=0;j--) {
          Vector<TuioCursor> cursors = gestureLog.get(j);
          // last one should = 0
          if ((isCursorExist(cursor.getCursorID(), cursors) == true)) {
            count1++;
          } else {
            break; 
          }
        }
        if ((count1>1) && (count1<10)) {
          return cursor;
        }      
      }
    }
  } 
  return null;
}

public TuioCursor getDragstart() { // 1: tap(0->1->0)
  int count1 = 0;
  int fingers = 0;
  if ((gestureLog.size() > 100)&&(gestureLog.get(gestureLog.size()-1).size() == 1)&&(gestureLog.get(gestureLog.size()-2).size() == 1)) {
    fingers = gestureLog.get(gestureLog.size()-1).size();
    for (int j=gestureLog.size()-3;j>=0;j--) {
      Vector<TuioCursor> cursors = gestureLog.get(j);
      // last one should = 0
      if (cursors.size()==1) {
        count1++;
      } else {
        break; 
      }
    }
    // move evaluation should added
    if (count1== 3&& fingers==1) {
      return gestureLog.get(gestureLog.size()-1).get(0);
    } 
    else if (fingers==0) {
      return null;
    }
  }
  return null;
}
public TuioCursor getDragmoving() { // 1: tap(1->1->0)
  if ((gestureLog.size() > 100)&&(gestureLog.get(gestureLog.size()-1).size() == 1)&&(getDraggingPhotos().size() > 0)) {
    return gestureLog.get(gestureLog.size()-1).get(0);
  }
  return null;
}
public TuioCursor getDragend() { // 1: tap(0)
  if ((getDraggingPhotos().size() > 0) && (gestureLog.size() > 100)&&(gestureLog.get(gestureLog.size()-1).size() == 0)) {
    for(int i=0;;i++){
      if(gestureLog.get(gestureLog.size()-2).size()!=0) {
        return gestureLog.get(gestureLog.size()-2-i).get(0);     
      } 
    }
  }
  return null;
}

// 3. update data
public void updateImageData() {
  TuioCursor cursor1 = null;
  TuioCursor cursor2 = null;

  int aliveCursor = client.getTuioCursors().size();
  switch (aliveCursor) {
    // if touch 1 finger
    // Image Position Modify
  case 1:
    Vector<TuioCursor> cursors = client.getTuioCursors();
    // loop - find cursor ( cursorID == 0 )
    for (TuioCursor tuioCursor : cursors) {
      if (0 == tuioCursor.getCursorID()) {
        imagePositionX = tuioCursor.getX() * SCREEN_SIZE_X;
        imagePositionY = tuioCursor.getY() * SCREEN_SIZE_Y;
      }
    }
    break;
    // if touch 2 fingers
    // Image Size Modify
  case 2:
    // loop - find two cursors ( cursor ID == 0 && ID == 1 )
    for (TuioCursor tuioCursor : client.getTuioCursors()) {
      if (0 == tuioCursor.getCursorID()) {
        cursor1 = tuioCursor;
      }
      if (1 == tuioCursor.getCursorID()) {
        cursor2 = tuioCursor;
      }
    }
    // check
    // Change Image Size
    if (cursor1 != null && cursor2 != null) {
      imageWidth = Math.abs(cursor1.getX() - cursor2.getX())
        * SCREEN_SIZE_X;
      imageHeight = Math.abs(cursor1.getY() - cursor2.getY())
        * SCREEN_SIZE_Y;
    }
    break;
    // if touch 3 fingers
    // Image Rotation Modify
  case 3:
    // find two cursors
    for (TuioCursor tuioCursor : client.getTuioCursors()) {
      if (0 == tuioCursor.getCursorID()) {
        cursor1 = tuioCursor;
      }
      if (1 == tuioCursor.getCursorID()) {
        cursor2 = tuioCursor;
      }
    }
    // check
    // calculate two cursors's gradient and rotate Image
    if (cursor1 != null && cursor2 != null) {
      // (X1, Y1) , (X2, Y2)
      // (Y2 - Y1) / (X2 - X1) == gradient
      // atan(gradient) == angle ( radian )
      // angle( radian ) * 180 / Pi == angle ( degree )
      float gradient = (cursor1.getY() - cursor2.getY())
        / (cursor1.getX() - cursor2.getX());
      imageRotate = (float)(Math.atan(gradient) * 180.0 /  Math.PI);
    }
    break;
  default:
    break;
  }
}

public JSONObject getGestureTargetPhoto(TuioCursor cursor) {
  float x = cursor.getX()*SCREEN_SIZE_X;
  float y = cursor.getY()*SCREEN_SIZE_Y;
  float normalizedX = 0 ,normalizedY =0;
  JSONObject cover = new JSONObject();
  // check cover photo 
  for(int i = data.size()-1;i>=0;i--){
    JSONObject album = data.getJSONObject(i);
    cover = album.getJSONObject("cover");
    pushMatrix();
    rotate( -radians(cover.getFloat("rotate")) );
    translate(-cover.getFloat("centerX"), -cover.getFloat("centerY"));
    normalizedX = modelX(x, y, 0);
    popMatrix();
    pushMatrix();
    rotate( HALF_PI-radians(cover.getFloat("rotate")) );
    translate(-cover.getFloat("centerX"), -cover.getFloat("centerY"));
    normalizedY = modelX(x, y, 0);
    popMatrix();    
    
    if((abs(normalizedX)<=(cover.getFloat("width")/2))&&(abs(normalizedY)<=(cover.getFloat("height")/2))){
      return cover;
    }
  }
  return null;  
}

// -1: not album cover, else positive: album index 
public int isCover(JSONObject targetPhoto) {
  JSONObject cover = new JSONObject();
  for(int i = 0;i<data.size();i++){
    JSONObject album = data.getJSONObject(i);
    cover = album.getJSONObject("cover");   
    if( cover.getString("path") == targetPhoto.getString("path")){
      return i; 
    }
  }
  return -1;
}
//---------------------------------------------
public void toggleAlbum(int albumIdx){
  // toggle isExpanded
  JSONObject album = data.getJSONObject(albumIdx);
  JSONObject cover = album.getJSONObject("cover");
  JSONArray photos = album.getJSONArray("photos");
  int numberOfPhoto = photos.size();
  
  boolean isExpanded = album.getBoolean("isExpanded");
  if(isExpanded == true) {
    album.setBoolean("isExpanded", false);
  } else {
    album.setBoolean("isExpanded", true);
  }
  isExpanded = album.getBoolean("isExpanded");
  
  if(isExpanded == true) {
    // if isExpanded is true, set values of photo object base on cover image.
    pushMatrix();
    // Positioning Image
    translate(cover.getFloat("centerX"), cover.getFloat("centerY"));
    // Rotate Image
    //rotate( radians(cover.getFloat("rotate")) );
    // align center
    //translate(- cover.getFloat("width") / 2, - cover.getFloat("height") / 2);
    translate(0, -50);
  
    for(int i=0;i<numberOfPhoto;i++){
      JSONObject photo = photos.getJSONObject(i);
      pushMatrix();    
      //println((i*1.0/numberOfPhoto)*360);
      rotate( radians((i*1.0/numberOfPhoto)*360) + 1 );      
      translate(0, 300);
      photo.setFloat("width", 200);   
      photo.setFloat("height", 100);
      photo.setFloat("rotate", 3.0);  

      // align center
      //translate(- photo.getFloat("width") / 2, - photo.getFloat("height") / 2);

      
      photo.setFloat("centerX", modelX(0,0,0));
      photo.setFloat("centerY",  modelY(0,0,0));  

    
      //album.setJSONObject("cover", cover);
      //data.setJSONObject(i, album);
    
      //image(coverImage, 0, 0, cover.getFloat("width"), cover.getFloat("height"));
      popMatrix();    
    }
    popMatrix();    
  } else {
    // if isExpanded is false, set values of photo object to 0
    
  }  
  //println(data);
}

public void tapHandler(TuioCursor tapCursor) {
  // get Target Photo JSON Object 
  JSONObject target = getGestureTargetPhoto(tapCursor);
  if (target != null) {  
    println("tap handler"); 
    int albumIndex = isCover(target);
    if(albumIndex != -1){
      toggleAlbum(albumIndex);
      moveAlbumFront(target);      
    }
  } 
}  

public void dragstartHandler(TuioCursor dragstartCursor) {
  JSONObject target = getGestureTargetPhoto(dragstartCursor);
  if (target != null) {  
    moveAlbumFront(target);
  }
  if(target != null) {
    System.out.println("drag start!");
    // turn Drag Flag On
    target.setBoolean("isDragging", true);
    target.setInt("draggingCursorID", dragstartCursor.getCursorID());
    target.setFloat("dragStartPositionX", dragstartCursor.getX()*SCREEN_SIZE_X - target.getFloat("centerX"));
    target.setFloat("dragStartPositionY", dragstartCursor.getY()*SCREEN_SIZE_Y - target.getFloat("centerY"));
  }
}

public void dragmoveHandler(TuioCursor dragmoveCursor) {
  JSONObject target = getGestureTargetPhoto(dragmoveCursor);
  if (target != null && target.getBoolean("isDragging") == true ) {  
    System.out.println("drag move!"); 
    // set Image position
    //target.getFloat("dragStartPositionX")
    target.setFloat("centerX", dragmoveCursor.getX()*SCREEN_SIZE_X - target.getFloat("dragStartPositionX"));
    target.setFloat("centerY", dragmoveCursor.getY()*SCREEN_SIZE_Y - target.getFloat("dragStartPositionY"));
  }
}

public void dragendHandler(TuioCursor dragendCursor) {
  JSONObject target = getGestureTargetPhoto(dragendCursor);
  if (target != null && target.getBoolean("isDragging") == true) {  
    println("drag end!"); 
    // set Image position
    target.setBoolean("isDragging", false);
  }
}

public ArrayList<File> getAlbumFolderList() {
  File currentRoot = new File(sketchPath(""));
  File[] rootFiles = currentRoot.listFiles();
  ArrayList<File> albumFolders = new ArrayList<File>();
  for (File file : rootFiles) {
    if (file.isDirectory())
      albumFolders.add(file);
  }
  return albumFolders;
}

public ArrayList<File> getImageFileList(File albumFolder) {
  File[] albumFiles = albumFolder.listFiles();
  ArrayList<File> imageFiles = new ArrayList<File>();

  // to find out what a valid image file suffic might be
  for (File file : albumFiles) {
    if ((!file.isDirectory())&&isImage(file)){
      imageFiles.add(file);
    }
  }
  return imageFiles;
}

public Boolean isImage(File file) {
  String[] list_of_imageFileSuffixes = { 
    "jpeg", "jpg", "tif", "tiff", "png"
  };
  for (String imageFileSuffix : list_of_imageFileSuffixes) {
    if (file.getPath().indexOf(imageFileSuffix) > -1) {
      return true;
    };
  } 
  return false;
}

public void initData() {
  ArrayList<File> albumFolders = getAlbumFolderList();
  ArrayList<File> albumFiles;
  int photoId = 0;

  for(int j=0; j < albumFolders.size();j++){
    File albumFolder = albumFolders.get(j);
    albumFiles = getImageFileList(albumFolder);
    JSONObject albumData = new JSONObject();
    albumData.setBoolean("isExpanded", false);

    JSONArray contentPhotos = new JSONArray();
    for(File albumFile : albumFiles) {      
      if(albumFile.getPath().indexOf("cover") > -1) {  
        JSONObject photObj = createPhotoObject(albumFile.getPath(), photoId);
        Images.add(loadImage(photObj.getString("path")));
        albumData.setJSONObject("cover", photObj); 
        photoId++;     
      } else {      
          JSONObject photObj = createPhotoObject(albumFile.getPath(), photoId);
          Images.add(loadImage(photObj.getString("path")));
          contentPhotos.append(photObj);
          photoId++; 
      }
    }
    albumData.setJSONArray("photos", contentPhotos);

    if(albumFiles.size()>0){
      data.append(albumData);
    }
  }
}

public void initCoverPosition() {
  int numOfAlbums = data.size();
  for(int i=0 ;i<numOfAlbums;i++){
    JSONObject album = data.getJSONObject(i);
    JSONObject cover = album.getJSONObject("cover");
    
    cover.setFloat("centerX", 150 + (290 * i));
    cover.setFloat("centerY", 150);    
    cover.setFloat("width", 200);   
    cover.setFloat("height", 200);
    cover.setFloat("rotate", 0.0);
  
    album.setJSONObject("cover", cover);
    data.setJSONObject(i, album);
  }
}

public void drawAlbums() {
  // drawing
  for(int i=0; i<data.size();i++) {
    JSONObject album = data.getJSONObject(i);
    Boolean isExpanded = album.getBoolean("isExpanded");
    JSONObject cover = album.getJSONObject("cover");
    JSONArray photos = album.getJSONArray("photos");

    int imgId = cover.getInt("id");
    
    PImage coverImage = Images.get(imgId);
    pushMatrix();
    // Positioning Image
    translate(cover.getFloat("centerX"), cover.getFloat("centerY"));
    // Rotate Image
    rotate( radians(cover.getFloat("rotate")) );
    // align center
    translate(- cover.getFloat("width") / 2, - cover.getFloat("height") / 2);
    // draw Image
    image(coverImage, 0, 0, cover.getFloat("width"), cover.getFloat("height"));
    popMatrix();
    
    if(isExpanded == true){
      for(int j=0;j<photos.size();j++){
        JSONObject photo = photos.getJSONObject(j);
        int photoId = photo.getInt("id");
        PImage photoImage = Images.get(photoId);
        pushMatrix();
        // Positioning Image
        translate(photo.getFloat("centerX"), photo.getFloat("centerY"));
        // Rotate Image
        rotate( radians(photo.getFloat("rotate")) );
        // align center
        translate(- photo.getFloat("width") / 2, - photo.getFloat("height") / 2);
        // draw Image
        image(photoImage, 0, 0, photo.getFloat("width"), cover.getFloat("height"));
        popMatrix();
      }
    }
  }
  
}

public JSONObject createPhotoObject(String pathStr, int photoId) {
  JSONObject photoData = new JSONObject();
  photoData.setFloat("centerX", 0.0);
  photoData.setFloat("centerY", 0.0);
  photoData.setFloat("width", 0.0);
  photoData.setFloat("height", 0.0);
  photoData.setFloat("rotate", 0.0);
  photoData.setBoolean("isDragging", false);
  photoData.setFloat("dragStartPositionX", 0.0);
  photoData.setFloat("dragStartPositionY", 0.0);
  photoData.setInt("id", photoId);      
  photoData.setString("path", pathStr);
  return  photoData;
}

public ArrayList<JSONObject> getDraggingPhotos() {
  ArrayList<JSONObject> draggingPhotos = new ArrayList<JSONObject>();
  // iterate cover
 // for(JSONObject album : data) {
  for(int i=0;i<data.size();i++) {
    JSONObject album = data.getJSONObject(i);
   JSONObject cover = album.getJSONObject("cover");
    if(cover.getBoolean("isDragging")==true) {
      draggingPhotos.add(cover);
    }
  }
  // iterate photo
  return draggingPhotos;
}

public void moveAlbumFront(JSONObject target) {
  JSONObject targetAlbum = new JSONObject();
  for(int i=0;i<data.size();i++) {
    JSONObject album = data.getJSONObject(i);
    JSONObject cover = album.getJSONObject("cover");
    if(cover.getString("path")==target.getString("path")) {
      targetAlbum = album;
      data.remove(i);
      data.append(targetAlbum);
      break;
    }
  }
}

