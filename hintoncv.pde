import java.util.*;
import gab.opencv.*;
import org.opencv.core.*;
import org.opencv.objdetect.*;

// image settings
final String IMG_PATH = "leworthy.jpg";
final int TARGET_WIDTH = 256;
final int TARGET_HEIGHT = 256;

final int DISPLAY_WIDTH = 512;
final int DISPLAY_HEIGHT = 512;

// hinton settings
final float MAG_INVERSE_OFFSET = 1; // Constant that determines how much stretching is applied to all hinton cells

final color BASE_DARK_COL = color(0, 63, 91);
final color BASE_LIGHT_COL = color(181, 173, 62);


Set<Integer> paintCols = new HashSet<Integer>();
//ArrayList<Integer> paintColsList;
final color PAINT_WHITE = color(252, 254, 255); // white - Titanium White #1380
final color PAINT_BLACK = color(36, 36, 36); // black - Carbon Black #1040
{
	Collections.addAll(paintCols,
			// ids based on Golden’s heavy body paints - https://www.goldenpaints.com/products/colors/heavy-body
			color(198, 48, 34), // red - Quinacridone Burnt Orange #1280
			color(233, 112, 39), // orange - Quinacridone / Nickel Azo Gold #1301
			color(249, 160, 32), // yellow - Indian Yellow Hue #1455
			color(21, 105, 71), // green - Phthalo Green (Yellow Shade) #1275
			color(22, 90, 89), // teal - Phthalo Green (Blue Shade) #1270
			color(52, 149, 207), // cyan - Manganese Blue Hue #1457
			color(19, 72, 200), // blue - Cobalt Blue #1140
			color(78, 70, 147), // purple - Ultramarine Violet #1401
			color(108, 41, 82), // violet - Cobalt Violet Hue #1465
			color(188, 29, 70) // magenta - Quinacridone Magenta #1305
	);
	
	//paintColsList = new ArrayList<Integer>(paintCols);
	//Collections.addAll(paintCols, PAINT_WHITE, PAINT_BLACK);
}

color bgCol = color(127);//color(63, 91, 101);
float bgLum;

// hog settings
final Size BLOCK_SIZE = new Size(8, 8);
final Size BLOCK_STRIDE = new Size(4, 4);
final Size CELL_SIZE = new Size(4, 4);
final int N_BUCKETS = 4;

PImage srcImage;
HintonCell[][] hintonCells;

void settings() {
	size(DISPLAY_WIDTH, DISPLAY_HEIGHT);
}

void setup() {
	// Image setup
	srcImage = loadImage(IMG_PATH);
	srcImage.resize(TARGET_WIDTH, TARGET_HEIGHT);

	//stroke(255, 0, 0);
	hintonCells = generateHintonCells(srcImage, BLOCK_SIZE, BLOCK_STRIDE, CELL_SIZE, N_BUCKETS);

	recalculateAvgCols(srcImage, CELL_SIZE);

	noLoop();
}

void draw() {
	clear();
	
	// Draw all hinton cells
	scale((float)DISPLAY_WIDTH / TARGET_WIDTH, (float)DISPLAY_HEIGHT / TARGET_HEIGHT);
	
	noStroke();
	ellipseMode(CENTER);
	rectMode(CENTER);
	
	background(bgCol);
	bgLum = luminance(bgCol);

	try {
		fillCells();
	} catch (Exception exception) {
		println(exception.getMessage());
		background(bgCol);
	}
}

void mouseClicked() {
	bgCol = color(max(0, min(255, 255 * mouseX / width)));
	
	println(brightness(bgCol));
	
	recalculateAvgCols(srcImage, CELL_SIZE);
	redraw();
}

//void mouseDragged() {
//	mouseClicked();
//}

void recalculateAvgCols(PImage srcImage, Size cellSize) {
	for (int y = 0; y < hintonCells.length; y++) {
		for (int x = 0; x < hintonCells[y].length; x++) {
			hintonCells[y][x].targetCol = avgColInCell(srcImage, y, x, cellSize);
		}
	}
}

color avgColInCell(PImage srcImage, int cellY, int cellX, Size cellSize) {
	int nPixelsInCell = (int)(cellSize.width * cellSize.height);
	
	int r = 0;
	int g = 0;
	int b = 0;
	
	for (int y = cellY * (int)cellSize.height; y < (cellY + 1) * cellSize.height; y++) {
		for (int x = cellX * (int)cellSize.width; x < (cellX + 1) * cellSize.width; x++) {
			color col = srcImage.get(x, y);
			
			r += red(col);
			g += green(col);
			b += blue(col);
		}
	}
	
	return color((float)r / nPixelsInCell, (float)g / nPixelsInCell, (float)b / nPixelsInCell);
}

void fillCells() {
	for (int y = 0; y < hintonCells.length; y++) {
		for (int x = 0; x < hintonCells[y].length; x++) {
			hintonCells[y][x].fillShape(y, x, CELL_SIZE, bgLum, bgCol, PAINT_BLACK, PAINT_WHITE);
		}
	}
}
