class HintonCell {
	public color avgCol;
	public ArrayList<Float> descriptorAngles;
  	public float magnitude;
  
	private float lumCache = Float.NaN;
	
	public HintonCell() {
		descriptorAngles = new ArrayList<Float>();
	}
	
	public HintonCell(color avgCol) {
		this();
		
		this.avgCol = avgCol;
	}

	// Only considers paint colors on the same side of the threshold as this cell's color
	public color closestPaintCol() {
		float leastDist = Float.POSITIVE_INFINITY;
		color closestCol = 0;

		boolean validColFound = false;

		boolean brighter = luminance(avgCol) - brightnessThreshold > 0;

		// not optimized
		for (color paintCol : paintCols) {
			//if (i == paintCols.size() && validColFound) {
			//	// Only use black/white if no other color was available
			//	break;
			//}
			
			//color paintCol = paintColsList.get(i);
	
			float paintColLum = luminance(paintCol);
			if (brighter && paintColLum - brightnessThreshold < 0 || !brighter && paintColLum - brightnessThreshold > 0) {
				continue;
  			}
	
			//float hueDiff = min(abs(hue(paintCol) - hue(avgCol)), 360 - abs(hue(paintCol) - hue(avgCol)));
			//float satDiff = saturation(paintCol) - saturation(avgCol);
			//float lumDiff = paintColLum - lum();
			
			//float dist = sq(hueDiff) + sq(satDiff) + sq(lumDiff);

			// Perceived color distance according to https://en.wikipedia.org/wiki/Color_difference
            float redDiff = (red(paintCol) - red(avgCol)) / 255;
            float greenDiff = (green(paintCol) - green(avgCol)) / 255;
            float blueDiff = (blue(paintCol) - blue(avgCol)) / 255;
            
            float redAvg = (red(paintCol) + red(avgCol)) / 2;
            
            float dist = (2 + redAvg / 256) * sq(redDiff) + 4 * sq(greenDiff) + (2 + (255 - redAvg) / 256) * sq(blueDiff);

			if (dist < leastDist) {
				leastDist = dist;
				closestCol = paintCol;
				
				validColFound = true;
			}
		}
	
   		if (!validColFound) {
	   		throw new RuntimeException("No paint color was found that can represent this cell color's brightness");
	   	}
	
		return closestCol;
	}

	public float lum() {
		if (Float.isNaN(lumCache)) {
			lumCache = luminance(avgCol);
		}
	
		return lumCache;
	}
	
	public float angle() {
		float cumSum = 0;
		for (float descriptorAngle : descriptorAngles) {
			cumSum += descriptorAngle;
		}
		
		return cumSum / descriptorAngles.size();
	}
	
	public void fillShape(int cellY, int cellX) {
		float brightnessDiff = lum() - brightnessThreshold;

		color col = colorFromBrightness(lum(), closestPaintCol());//colorFromBrightness(lum());
		float unitWidthLinear = brightnessDiff / (luminance(col) - brightnessThreshold);
		
		//float unitWidth = sqrt(unitWidthLinear); // square
		float unitWidth = 2 * sqrt(unitWidthLinear / PI); // circle
		
		float x = (cellX + .5) * (float)hog.get_cellSize().width;
		float y = (cellY + .5) * (float)hog.get_cellSize().height;
		
		float magInverse = 1 - magnitude * MAG_INVERSE_OFFSET;
		
		push();
		
		fill(col);
		
		translate(x, y);
		rotate(angle());
		scale(1 / magInverse, magInverse);
		
		//rect(0, 0, unitWidth * (float)hog.get_cellSize().width, unitWidth * (float)hog.get_cellSize().height);
		ellipse(0, 0, unitWidth * (float)hog.get_cellSize().width, unitWidth * (float)hog.get_cellSize().height);
		
		pop();
	}
}

color colorFromBrightness(float lum, color base) {
	color a;
	color b;
	float x;

	if (lum < brightnessThreshold) {
		a = PAINT_BLACK;
		b = base;
		//a = color(0);
		//b = BASE_DARK_COL;
	
		x = lum / (brightnessThreshold / 255);
	} else {
		a = base;
		b = PAINT_WHITE;
		//a = BASE_LIGHT_COL;
		//b = color(255);
	
		x = (lum - brightnessThreshold) / (1 - brightnessThreshold / 255);
	}
	
	return lerpColor(a, b, x / 255);
}

float luminance(color col) {
	return sqrt(0.299 * red(col) * red(col) + 0.587 * green(col) * green(col) + 0.114 * blue(col) * blue(col));
}
