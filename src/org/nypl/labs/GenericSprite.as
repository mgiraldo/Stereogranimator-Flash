package org.nypl.labs {
	import flash.display.Sprite;

	/**
	 * @author Mauricio Giraldo Arteaga <mauriciogiraldo@nypl.org> 
	 * NYPL Labs
	 * http://www.nypl.org
	 */
	public class GenericSprite extends Sprite {
		public var mx:Number = 0;
		public var my:Number = 0;
		public var sq1x:Number = 0;
		public var sq1y:Number = 0;
		public var sq2x:Number = 0;
		public var sq2y:Number = 0;
		public var over:Boolean = false;
		public var dragging:Boolean = false;
		public function GenericSprite() {
		}
	}
}
