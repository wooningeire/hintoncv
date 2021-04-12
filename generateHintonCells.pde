/* Some ad hoc terminology:
 * * A *descriptor cell* is a representation of a cell in a block, found in the HOGDescriptor.
 * * A *Hinton cell* represents all of the descriptor cells that belong to that Hinton cell's coordinates.
 * Depending on the block size, block stride size, and cell size, there can be multiple descriptor cells in the same spot.
 * (TODO Can they be misaligned?)
 */

HintonCell[][] generateHintonCells(PImage srcImage, Size blockSize, Size blockStrideSize, Size cellSize, int nBuckets) {
	OpenCV ocv = new OpenCV(this, srcImage);
	
	Mat srcMat = ocv.getGray();
	Size winSize = new Size(srcImage.width, srcImage.height);

	int nCellsY = (int)(winSize.height / cellSize.height);
	int nCellsX = (int)(winSize.width / cellSize.width);
	HintonCell[][] hintonCells = new HintonCell[nCellsY][nCellsX];
	
	HOGDescriptor hog = new HOGDescriptor(winSize, blockSize, blockStrideSize, cellSize, nBuckets);
	MatOfFloat destMat = new MatOfFloat();
	hog.compute(srcMat, destMat);
	
	computeHintonCellsAngleAndWeight(hog, hintonCells, destMat);
	
	return hintonCells;
}

void computeHintonCellsAngleAndWeight(HOGDescriptor hog, HintonCell[][] hintonCells, MatOfFloat destMat) {
	// Maximum positions on the image for each block (any higher and the block will exceed the image boundaries)
	// Does not factor in padding
	int maxBlockY = (int)((hog.get_winSize().height - (hog.get_blockSize().height - hog.get_blockStride().height)) / hog.get_blockStride().height);
	//int maxBlockX = (int)((hog.get_winSize().width - (hog.get_blockSize().width - hog.get_blockStride().width)) / hog.get_blockStride().width); // unused
	
	int nCellsPerBlockY = (int)(hog.get_blockSize().height / hog.get_cellSize().height);
	int nCellsPerBlockX = (int)(hog.get_blockSize().width / hog.get_cellSize().width);
	
	// Iterate through the first descriptor contents in the HOG result
	
	// Blocks themselves
	int blockX = 0; // Represents the `blockX`th block from the left of the descriptor result
	int blockY = 0; // Represents the `blockY`th block from the top of the descriptor result
	
	// Cells within each block
	int blockCellX = 0; // Represents the `blockCellX`th cell from the left within the block
	int blockCellY = 0; // Represents the `blockCellY`th cell from the top within the block
	
	for (long index = 0; index < hog.getDescriptorSize(); index += hog.get_nbins()) {
		float y = (float)(hog.get_blockStride().height * blockY + hog.get_cellSize().height * blockCellY); // Y coordinate (px) of the current cell
		float x = (float)(hog.get_blockStride().width * blockX + hog.get_cellSize().width * blockCellX); // X coordinate (px) of the current cell
		
		int cellY = (int)(y / hog.get_cellSize().height);
		int cellX = (int)(x / hog.get_cellSize().width);

		countDescriptorCellAngleAndWeight(index, cellY, cellX, hog, hintonCells, destMat);
		
		// Increment all position markers (equivalent alternative to having 5 nested `for`-loops)
		blockCellY++;
		
		blockCellX += blockCellY / nCellsPerBlockY; // If `blockCellY` > `cellsPerBlockY`, `blockCellX` will increment by 1, otherwise it will not increment
		blockCellY %= nCellsPerBlockY; // If `blockCellX` was incremented, `blockCellY` will be reset down to 0
		
		blockY += blockCellX / nCellsPerBlockX;
		blockCellX %= nCellsPerBlockX;
		
		blockX += blockY / maxBlockY;
		blockY %= maxBlockY;
		
		// iDescriptor += ...
		// blockX %= ...
	}
}

void countDescriptorCellAngleAndWeight(long index, int cellY, int cellX, HOGDescriptor hog, HintonCell[][] hintonCells, MatOfFloat destMat) {
	HintonCell hintonCell = hintonCells[cellY][cellX];
	if (hintonCell == null) {
		hintonCells[cellY][cellX] = hintonCell = new HintonCell();
	}
	
	float maxWeight = 0;
	float angle = 0;
	
	for (int i = 0; i < hog.get_nbins(); i++) {
		double weight = destMat.get((int)index + i, 0)[0];

		if (weight > maxWeight) {
			maxWeight = (float)weight;
			angle = i * PI / hog.get_nbins();
		}
	}
	
	hintonCell.countDescriptorCell(angle, maxWeight);
	
	// Draw normal lines
	//float r = 1;
	//line(x - r * cos(angle), y + r * sin(angle), x + r * cos(angle), y - r * sin(angle));
}
