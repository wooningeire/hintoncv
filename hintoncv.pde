import java.util.*;
import gab.opencv.*;
import org.opencv.core.*;
import org.opencv.objdetect.*;

// image settings
final String IMG_PATH = "leworthy.jpg";

// hinton settings
final float MAG_INVERSE_OFFSET = 1;

final color BASE_DARK_COL = color(0, 63, 91);
final color BASE_LIGHT_COL = color(181, 173, 62);


Set<Integer> paintCols = new HashSet<Integer>();
//ArrayList<Integer> paintColsList;
final color PAINT_WHITE = color(252, 254, 255); // white - Titanium White #1380
final color PAINT_BLACK = color(36, 36, 36); // black - Carbon Black #1040
{
    Collections.addAll(paintCols,
    		// ids based on Golden’s heavy body paints - https://www.goldenpaints.com/products/colors/heavy-body
    		color(191, 1, 1), // red - Pyrolle Red #1277
            color(253, 68, 1), // orange - C.P. Cadmium Orange #1070
            color(249, 160, 32), // orange-yellow - Indian Yellow Hue #1455
            color(252, 231, 2), // yellow - Benzimidazolone Yellow Light #1009
            color(21, 105, 71), // green - Phthalo Green (Yellow Shade) #1275
            color(22, 90, 89), // cyan - Phthalo Green (Blue Shade) #1270
            color(35, 70, 170), // blue - Cobalt Blue Hue #1556
            color(78, 70, 147), // purple - Ultramarine Violet #1401
            color(108, 41, 82), // violet - Cobalt Violet Hue #1465
            color(162, 6, 43) // magenta - Quinacridone Magenta #1305
    );
    
    //paintColsList = new ArrayList<Integer>(paintCols);
    //Collections.addAll(paintColsList, PAINT_WHITE, PAINT_BLACK);
}

color bgCol = color(127);//color(63, 91, 101);
float brightnessThreshold;

// hog settings
final Size BLOCK_SIZE = new Size(8, 8);
final Size BLOCK_STRIDE = new Size(4, 4);
final Size CELL_SIZE = new Size(4, 4);
final int N_BUCKETS = 4;

OpenCV ocv;
PImage src;
PImage result;

Mat matSrc;
MatOfFloat matDest;
HOGDescriptor hog;

HintonCell[][] hintonCells;

void settings() {
	size(512, 512);
}

void setup() {
	// Image setup
	src = loadImage(IMG_PATH);
	src.resize(256, 256);
	
	ocv = new OpenCV(this, src);
	
	matSrc = ocv.getGray();
	matDest = new MatOfFloat();
	
	// Calculate directions
	hog = new HOGDescriptor(new Size(src.width, src.height), BLOCK_SIZE, BLOCK_STRIDE, CELL_SIZE, N_BUCKETS);
	hog.compute(matSrc, matDest);
	
	// Calculate and generate graphics

	int cellsWinY = (int)(hog.get_winSize().height / hog.get_cellSize().height);
	int cellsWinX = (int)(hog.get_winSize().width / hog.get_cellSize().width);
	hintonCells = new HintonCell[cellsWinY][cellsWinX];
	
	//stroke(255, 0, 0);
	
	// Create the hinton cells and assign their angles and average colors
	iterateDescriptors();

	noLoop();
}

void draw() {
    clear();
    
    // Draw all hinton cells
    scale(2, 2);
    
    noStroke();
    ellipseMode(CENTER);
    rectMode(CENTER);
    
    background(bgCol);
    brightnessThreshold = luminance(bgCol);

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
    
    recalcAvgCols();
    redraw();
}

//void mouseDragged() {
//    mouseClicked();
//}

color avgCol(int y, int x) {
	int count = (int)(hog.get_cellSize().width * hog.get_cellSize().height);
	
	int r = 0;
	int g = 0;
	int b = 0;
	
	for (int iY = y * (int)hog.get_cellSize().height; iY < (y + 1) * hog.get_cellSize().height; iY++) {
		for (int iX = x * (int)hog.get_cellSize().width; iX < (x + 1) * hog.get_cellSize().width; iX++) {
			color col = src.get(iX, iY);
			
			r += red(col);
			g += green(col);
			b += blue(col);
		}
	}
	
	return color((float)r / count, (float)g / count, (float)b / count);
}

void iterateDescriptors() {
	// Maximum positions on the image for each block (any higher and the block will exceed the image boundaries)
	// Does not factor in padding
	int maxBlockY = (int)((hog.get_winSize().height - (hog.get_blockSize().height - hog.get_blockStride().height)) / hog.get_blockStride().height);
	//int maxBlockX = (int)((hog.get_winSize().width - (hog.get_blockSize().width - hog.get_blockStride().width)) / hog.get_blockStride().width); // unused
	
	int cellsPerBlockY = (int)(hog.get_blockSize().height / hog.get_cellSize().height);
	int cellsPerBlockX = (int)(hog.get_blockSize().width / hog.get_cellSize().width);
	
	// Iterate through the first descriptor contents in the HOG result
	
	// Blocks themselves
	int blockX = 0;
	int blockY = 0;
	
	// Cells within each block
	int blockCellX = 0;
	int blockCellY = 0;
	
	for (long index = 0; index < hog.getDescriptorSize(); index += hog.get_nbins()) {
		float mid = (float)hog.get_cellSize().width / 2;

		float y = (float)(hog.get_blockStride().height * blockY + hog.get_cellSize().height * blockCellY);
		float x = (float)(hog.get_blockStride().width * blockX + hog.get_cellSize().width * blockCellX);
		
		int cellY = (int)(y / hog.get_cellSize().height);
		int cellX = (int)(x / hog.get_cellSize().width);

		createCell(index, cellY, cellX, y + mid, x + mid);
		
		
		// Increment all position markers
		blockCellY++;
		
		blockCellX += blockCellY / cellsPerBlockY;
		blockCellY %= cellsPerBlockY;
		
		blockY += blockCellX / cellsPerBlockX;
		blockCellX %= cellsPerBlockX;
		
		blockX += blockY / maxBlockY;
		blockY %= maxBlockY;
		
		// iDescriptor += ...
		// blockX %= ...
	}
}

void createCell(long index, int cellY, int cellX, float y, float x) {
	float maxWeight = 0;
	float angle = 0;
	
	for (int j = 0; j < hog.get_nbins(); j++) {
		double weight = matDest.get((int)index + j, 0)[0];
		
		if (weight > maxWeight) {
			maxWeight = (float)weight;
			angle = j * PI / hog.get_nbins();
		}
	}
	
	HintonCell cell = new HintonCell(avgCol(cellY, cellX));
    hintonCells[cellY][cellX] = cell;
	cell.magnitude = maxWeight;
	cell.descriptorAngles.add(angle);

	
	// Draws normal lines
	//float r = 1;
	//line(x - r * cos(angle), y + r * sin(angle), x + r * cos(angle), y - r * sin(angle));
}

void recalcAvgCols() {
    for (int y = 0; y < hintonCells.length; y++) {
        for (int x = 0; x < hintonCells[y].length; x++) {
            hintonCells[y][x].avgCol = avgCol(y, x);
        }
    }
}

void fillCells() {
	for (int y = 0; y < hintonCells.length; y++) {
		for (int x = 0; x < hintonCells[y].length; x++) {
			hintonCells[y][x].fillShape(y, x);
		}
	}
}
