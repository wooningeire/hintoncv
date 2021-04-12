class HintonCell {
  private color targetCol;

	private float angle;
	private float magnitude;
	private float nDescriptorCells = 0;

	private float lumCache = Float.NaN;

	HintonCell() {}

	// Only considers paint colors on the same side of the threshold as this cell's color
	Optional<Integer> closestPaintCol(float lumThreshold) {
		float leastDist = Float.POSITIVE_INFINITY;
		Optional<Integer> closestCol = Optional.empty();

		boolean cellBrighterThanBg = luminance(targetCol) - lumThreshold > 0;

		// not optimized
		for (color paintCol : paintCols) {
			//if (i == paintCols.size() && validColFound) {
			//	// Only use black/white if no other color was available
			//	break;
			//}
			
			//color paintCol = paintColsList.get(i);

			float paintColLum = luminance(paintCol);
			boolean paintColBrighterThanBg = paintColLum - lumThreshold > 0;

			boolean brightnessDirectionMatches = cellBrighterThanBg && paintColBrighterThanBg || !cellBrighterThanBg && !paintColBrighterThanBg;
			if (!brightnessDirectionMatches) continue;

			float dist = colorDiff(paintCol, targetCol);
			if (dist < leastDist) {
				leastDist = dist;
				closestCol = Optional.of(paintCol);
			}
		}
	
		return closestCol;
	}

  void setTargetCol(color targetCol) {
    lumCache = Float.NaN;
    this.targetCol = targetCol;
  }
  color getTargetCol() { return this.targetCol; }

	float lum() {
		return Float.isNaN(lumCache)
				? lumCache = luminance(targetCol)
				: lumCache;
	}

	void countDescriptorCell(float descriptorAngle, float maxWeight) {
		nDescriptorCells++;
	
		// Equivalent to calculating the average
		// TODO shouldn't average angles like this
		angle = ((nDescriptorCells - 1.) / nDescriptorCells) * angle + (1. / nDescriptorCells) * descriptorAngle;
		magnitude = ((nDescriptorCells - 1.) / nDescriptorCells) * magnitude + (1. / nDescriptorCells) * maxWeight;
	}
	
	void fillShape(int cellY, int cellX, Size cellSize, float lumThreshold, color fallbackCol, color darkestCol, color lightestCol) {
		float brightnessDiff = lum() - lumThreshold;

		color col = lerpColToExtreme(lum(), closestPaintCol(lumThreshold).orElse(fallbackCol), lumThreshold, darkestCol, lightestCol);//colorFromBrightness(lum());
		float unitWidthLinear = brightnessDiff / (luminance(col) - lumThreshold);
		
		//float unitWidth = sqrt(unitWidthLinear); // square
		float unitWidth = 2 * sqrt(unitWidthLinear / PI); // circle
		
		float x = (cellX + .5) * (float)cellSize.width;
		float y = (cellY + .5) * (float)cellSize.height;
		
		float magInverse = 1 - magnitude * MAG_INVERSE_OFFSET;
		
		push();
		
		fill(col);
		
		translate(x, y);
		rotate(angle);
		scale(1 / magInverse, magInverse);
		
		//rect(0, 0, unitWidth * (float)cellSize.width, unitWidth * (float)cellSize.height);
		ellipse(0, 0, unitWidth * (float)cellSize.width, unitWidth * (float)cellSize.height);
		
		pop();
	}
}

color lerpColToExtreme(float lum, color baseCol, float lumThreshold, color darkestCol, color lightestCol) {
	color darkCol;
	color lightCol;
	float lerpAmount;

	if (lum < lumThreshold) {
		darkCol = darkestCol;
		lightCol = baseCol;
		//darkCol = color(0);
		//lightCol = BASE_DARK_COL;
	
		lerpAmount = lum / (lumThreshold / 255);
	} else {
		darkCol = baseCol;
		lightCol = lightestCol;
		//darkCol = BASE_LIGHT_COL;
		//lightCol = color(255);
	
		lerpAmount = (lum - lumThreshold) / (1 - lumThreshold / 255);
	}
	
	return lerpColor(darkCol, lightCol, lerpAmount / 255);
}

float colorDiff(color col0, color col1) {
	//float hueDiff = min(abs(hue(paintCol) - hue(avgCol)), 360 - abs(hue(paintCol) - hue(avgCol)));
	//float satDiff = saturation(paintCol) - saturation(avgCol);
	//float lumDiff = paintColLum - lum();
	
	//float dist = sq(hueDiff) + sq(satDiff) + sq(lumDiff);

	// Perceived color distance according to https://en.wikipedia.org/wiki/Color_difference
	float redDiff = (red(col1) - red(col0)) / 255;
	float greenDiff = (green(col1) - green(col0)) / 255;
	float blueDiff = (blue(col1) - blue(col0)) / 255;
	
	float redAvg = (red(col1) + red(col0)) / 2;
	
	return (2 + redAvg / 256) * sq(redDiff) + 4 * sq(greenDiff) + (2 + (255 - redAvg) / 256) * sq(blueDiff);
}

float luminance(color col) {
	return sqrt(0.299 * red(col) * red(col) + 0.587 * green(col) * green(col) + 0.114 * blue(col) * blue(col));
}
