package org.nypl.labs {
	import flash.external.ExternalInterface;
	import flash.system.LoaderContext;
	import flash.system.Security;

	import com.adobe.serialization.json.JSON;

	import flash.events.HTTPStatusEvent;
	import flash.net.navigateToURL;
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	import flash.display.BitmapDataChannel;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.net.URLRequest;
	import flash.display.Loader;
	import flash.events.IOErrorEvent;
	import flash.events.Event;
	import flash.display.Graphics;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.events.MouseEvent;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.utils.ByteArray;
	import flash.display.SimpleButton;

	/**
	 * @author Mauricio Giraldo Arteaga <mauriciogiraldo@nypl.org> 
	 * NYPL Labs
	 * http://www.nypl.org
	 */
	public class Stereogranimator extends MovieClip {
		private var bmp : Bitmap;
		private var vert_sprite : Vertical;
		private var corner_sprites : Vector.<Corner>;
		// anaglyph mode private vars
		private var processcanvas : Sprite;
		private var resultcanvas : Sprite;
		private var ctx3D : BitmapData;
		private var ctxbase : BitmapData;
		private var leftbmp : Bitmap;
		private var rightbmp : Bitmap;
		private var processbmp : Bitmap;
		private var leftimgdata_array : ByteArray;
		private var rightimgdata_array : ByteArray;
		// interface elements
		private static const CORNER_OFFSET : Number = 10;
		private static const canvasWidth : Number = 800;
		private static const canvasHeight : Number = 540;
		// background
		private var bg : Sprite;
		// squares
		private var sq1 : Square;
		private var sq2 : Square;
		// element private vars
		// square positions
		private var sq1x : Number = 0;
		private var sq1y : Number = 0;
		private var sq2x : Number = 0;
		private var sq2y : Number = 0;
		private var vertx : Number = 0;
		private var verty : Number = 0;
		// square scaling
		private var hsize : Number = 300;
		private var vsize : Number = 360;
		private var MINSIZE : Number = 80;
		private var MAXW : Number = 399;
		private var MAXH : Number = 490;
		private static const SLOWSPEED : Number = 200;
		private static const MEDSPEED : Number = 140;
		private static const FASTSPEED : Number = 80;
		// vertical bar values
		private var VERTWIDTH : Number = 10;
		private var VERTHEIGHT : Number = 60;
		// animation preview tick and speed
		private var now : Number = 0;
		private var lasttick : Number = 0;
		private var speed : Number = FASTSPEED;
		private var frame : Number = 1;
		private var OFFSET : Number = 0;
		private var INSET : Number = 10;
		private var THICK : Number = 2;
		private var COLOR : Number = 0xffffff;
		private var OVERCOLOR : Number = 0xff0000;
		private var MAINFILL : Number = 0x000000;
		private var BACKFILL : Number = 0x000000;
		private var update : Boolean = true;
		private var first : Boolean = true;
		private var mode : String = "GIF";
		private var index : String = "";
		private var ticker : Timer;
		private var baseurl : String;
		private var loader : Loader = new Loader();
		// IN-FLASH STUFF
		public var btnNext : SimpleButton;
		public var canvas : MovieClip;
		public var preview : MovieClip;
		public var toggleClip : MovieClip;
		public var hiddenClip : MovieClip;
		public var generatingClip : MovieClip;

		public function Stereogranimator() {
			index = stage.loaderInfo.parameters.index == undefined ? "G92F031_020F" : stage.loaderInfo.parameters.index;
			baseurl = stage.loaderInfo.parameters.host == undefined ? "http://localhost:3000" : stage.loaderInfo.parameters.host;
			addEventListener(Event.ADDED_TO_STAGE, init);
		}

		public function init(e : Event) : void {
			removeEventListener(Event.ADDED_TO_STAGE, init);

			generatingClip.visible = false;

			changeSpeed(speed);
			toggleMode(mode);

			loadPhoto(index);

			ticker = new Timer(10);
			ticker.addEventListener("timer", tick);
		}

		public function prepareInterface() : void {
			vert_sprite = new Vertical();
			vert_sprite.x = vertx;
			vert_sprite.y = verty;
			canvas.addChild(vert_sprite);
			// eight corners
			var i : Number, crnr : Corner;
			corner_sprites = new Vector.<Corner>();
			for (i = 0;i < 8;++i) {
				crnr = new Corner();
				crnr.mysquare = (i < 4) ? sq1 : sq2;
				crnr.mode = (i < 4) ? "left" : "right";
				// multiplier for corner position
				if (i % 4 == 0) {
					crnr.xfactor = 0;
					crnr.yfactor = 0;
				} else if (i % 4 == 1) {
					crnr.xfactor = 1;
					crnr.yfactor = 0;
				} else if (i % 4 == 2) {
					crnr.xfactor = 0;
					crnr.yfactor = 1;
				} else if (i % 4 == 3) {
					crnr.xfactor = 1;
					crnr.yfactor = 1;
				}
				canvas.addChild(crnr);
				corner_sprites.push(crnr);
			}
			trace("prepared sprite");
		}

		public function centerPhoto() : void {
			// center horizontally
			OFFSET = Math.floor((canvasWidth - bmp.width) / 2);

			bmp.x = OFFSET;
			bmp.y = 0;
		}

		public function run() : void {
			// init animation timer
			lasttick = getTimer();

			centerPhoto();

			processbmp = new Bitmap();
			preview.addChild(processbmp);

			// background black
			bg = new Sprite();
			canvas.addChild(bg);

			// starting points for squares
			sq1x = bmp.x + Math.round(bmp.width / 2) - hsize - INSET;
			sq1y = bmp.y + Math.round(bmp.height / 2) - (vsize / 2);
			sq2x = bmp.x + Math.round(bmp.width / 2) + INSET;
			sq2y = bmp.y + Math.round(bmp.height / 2) - (vsize / 2);

			// starting point for vertical bar
			vertx = bmp.x + (bmp.width / 2);
			verty = bmp.y + (bmp.height / 2);

			// the squares
			sq1 = new Square();
			// to control for mouse position when dragging
			canvas.addChild(sq1);

			sq2 = new Square();
			// to control for mouse position when dragging
			canvas.addChild(sq2);

			ticker.start();
		}

		public function addInteractivity() : void {
			btnNext.addEventListener(MouseEvent.CLICK, generate);

			toggleClip.gifClip.gifBtn.addEventListener(MouseEvent.CLICK, function() : void {
				toggleMode("GIF");
			});
			toggleClip.anaClip.anaBtn.addEventListener(MouseEvent.CLICK, function() : void {
				toggleMode("ANAGLYPH");
			});

			toggleClip.gifClip.slowClip.slowBtn.addEventListener(MouseEvent.CLICK, function() : void {
				changeSpeed(SLOWSPEED);
			});
			toggleClip.gifClip.medClip.medBtn.addEventListener(MouseEvent.CLICK, function() : void {
				changeSpeed(MEDSPEED);
			});
			toggleClip.gifClip.fastClip.fastBtn.addEventListener(MouseEvent.CLICK, function() : void {
				changeSpeed(FASTSPEED);
			});

			// handle movement for VERTICAL handle
			// wrapper function to provide scope for the event handlers:
			vert_sprite.addEventListener(MouseEvent.MOUSE_DOWN, function(e : MouseEvent) : void {
				var tg : Vertical = Vertical(e.target);
				tg.dragging = true;
				// drag
				tg.mx = vertx - tg.stage.mouseX;
				tg.sq1x = vertx - sq1x;
				tg.sq2x = vertx - sq2x;
			});
			vert_sprite.addEventListener(MouseEvent.MOUSE_UP, function(e : MouseEvent) : void {
				var tg : Vertical = Vertical(e.target);
				tg.dragging = false;
			});
			vert_sprite.addEventListener(MouseEvent.MOUSE_MOVE, function(e : MouseEvent) : void {
				var tg : Vertical = Vertical(e.target);
				if (tg.dragging) {
					vertx = tg.stage.mouseX + tg.mx;
					// move squares along with bar
					sq1x = vertx - tg.sq1x;
					sq2x = vertx - tg.sq2x;
					// indicate that the stage should be updated on the next tick:
					update = true;
				}
			});
			vert_sprite.addEventListener(MouseEvent.ROLL_OVER, function(e : MouseEvent) : void {
				var tg : Vertical = Vertical(e.target);
				tg.over = true;
				update = true;
			});
			vert_sprite.addEventListener(MouseEvent.ROLL_OUT, function(e : MouseEvent) : void {
				var tg : Vertical = Vertical(e.target);
				tg.over = false;
				tg.dragging = false;
				update = true;
			});

			// handle movement for LEFT square
			// wrapper function to provide scope for the event handlers:
			sq1.addEventListener(MouseEvent.MOUSE_DOWN, function(e : MouseEvent) : void {
				var tg : Square = Square(e.target);
				// drag
				tg.dragging = true;
				// save mouse position for future reference
				tg.mx = sq1x - tg.stage.mouseX;
				tg.my = sq1y - tg.stage.mouseY;
			});
			sq1.addEventListener(MouseEvent.MOUSE_UP, function(e : MouseEvent) : void {
				var tg : Square = Square(e.target);
				tg.dragging = false;
			});
			sq1.addEventListener(MouseEvent.MOUSE_MOVE, function(e : MouseEvent) : void {
				var tg : Square = Square(e.target);
				if (tg.dragging) {
					if (tg.stage.mouseX + tg.mx + hsize < vertx) {
						sq1x = tg.stage.mouseX + tg.mx;
					} else {
						sq1x = vertx - hsize - 1;
					}
					sq1y = tg.stage.mouseY + tg.my;
					// move the other square in a mirror direction
					var d : Number = vertx - sq1x;
					sq2x = vertx + d - hsize;
					sq2y = sq1y;
					// indicate that the stage should be updated on the next tick:
					update = true;
				}
			});
			sq1.addEventListener(MouseEvent.ROLL_OVER, function(e : MouseEvent) : void {
				var tg : Square = Square(e.target);
				tg.over = true;
				update = true;
			});
			sq1.addEventListener(MouseEvent.ROLL_OUT, function(e : MouseEvent) : void {
				var tg : Square = Square(e.target);
				tg.over = false;
				tg.dragging = false;
				update = true;
			});

			// handle movement for RIGHT square
			// wrapper function to provide scope for the event handlers:
			sq2.addEventListener(MouseEvent.MOUSE_DOWN, function(e : MouseEvent) : void {
				var tg : Square = Square(e.target);
				// drag
				tg.dragging = true;
				// save mouse position for future reference
				tg.mx = sq2x - tg.stage.mouseX;
				tg.my = sq2y - tg.stage.mouseY;
			});
			sq2.addEventListener(MouseEvent.MOUSE_UP, function(e : MouseEvent) : void {
				var tg : Square = Square(e.target);
				tg.dragging = false;
			});
			sq2.addEventListener(MouseEvent.MOUSE_MOVE, function(e : MouseEvent) : void {
				var tg : Square = Square(e.target);
				if (tg.dragging) {
					if (tg.stage.mouseX + tg.mx > vertx) {
						sq2x = tg.stage.mouseX + tg.mx;
					} else {
						sq2x = vertx + 1;
					}
					sq2y = tg.stage.mouseY + tg.my;
					// move the other square in a mirror direction
					var d : Number = vertx - sq2x;
					sq1x = vertx + d - hsize;
					sq1y = sq2y;
					// indicate that the stage should be updated on the next tick:
					update = true;
				}
			});
			sq2.addEventListener(MouseEvent.ROLL_OVER, function(e : MouseEvent) : void {
				var tg : Square = Square(e.target);
				tg.over = true;
				update = true;
			});
			sq2.addEventListener(MouseEvent.ROLL_OUT, function(e : MouseEvent) : void {
				var tg : Square = Square(e.target);
				tg.over = false;
				tg.dragging = false;
				update = true;
			});

			// handle RESIZING
			// generic interaction for eight corners
			var i : Number, tg : Corner;
			for (i = 0;i < 8;++i) {
				tg = corner_sprites[i];
				tg.addEventListener(MouseEvent.MOUSE_DOWN, function(e : MouseEvent) : void {
					var t : Corner = Corner(e.target);
					// drag
					t.dragging = true;
					// save mouse position for future reference
					t.mx = tg.stage.mouseX - t.x;
					t.my = tg.stage.mouseY - t.y;
					t.sh = hsize;
					t.sv = vsize;
					t.x1 = (t.mysquare == sq1) ? sq1x : sq2x;
					t.y1 = (t.mysquare == sq1) ? sq1y : sq2y;
					t.x2 = t.x1 + hsize;
					t.y2 = t.y1 + vsize;
				});
				tg.addEventListener(MouseEvent.MOUSE_UP, function(e : MouseEvent) : void {
					var t : Corner = Corner(e.target);
					// drag
					t.dragging = false;
				});
				tg.addEventListener(MouseEvent.ROLL_OVER, function(e : MouseEvent) : void {
					var t : Corner = Corner(e.target);
					t.over = true;
					update = true;
				});
				tg.addEventListener(MouseEvent.ROLL_OUT, function(e : MouseEvent) : void {
					var t : Corner = Corner(e.target);
					t.over = false;
					t.dragging = false;
					update = true;
				});
			}
			// specific interaction for corners
			(function(tg : Corner) : void {
				tg.addEventListener(MouseEvent.MOUSE_MOVE, function(e : MouseEvent) : void {
					if (tg.dragging) {
						tg.x = tg.stage.mouseX - tg.mx;
						if (tg.mode == "right" && tg.x - CORNER_OFFSET < vertx) {
							// prevent from moving to left side
							tg.x = vertx + CORNER_OFFSET + 1;
						}
						if (tg.x > tg.x2 - MINSIZE) {
							tg.x = tg.x2 - MINSIZE;
						}
						hsize = tg.x2 - (tg.x - CORNER_OFFSET);
						if (hsize < MINSIZE) {
							hsize = MINSIZE;
						}
						tg.y = tg.stage.mouseY - tg.my;
						if (tg.y > tg.y2 - MINSIZE) {
							tg.y = tg.y2 - MINSIZE;
						}
						vsize = tg.y2 - (tg.y - CORNER_OFFSET);
						if (vsize < MINSIZE) {
							vsize = MINSIZE;
						}
						if (tg.mode == "left") {
							sq1x = tg.x - CORNER_OFFSET;
							sq2x = vertx + vertx - sq1x - hsize;
						} else {
							sq2x = tg.x - CORNER_OFFSET;
							sq1x = vertx - (sq2x - vertx) - hsize;
						}
						// .y is common to both
						sq1y = tg.y - CORNER_OFFSET;
						sq2y = sq1y;
						// indicate that the stage should be updated on the next tick:
						update = true;
					}
				});
			})(corner_sprites[0]);
			(function(tg : Corner) : void {
				tg.addEventListener(MouseEvent.MOUSE_MOVE, function(e : MouseEvent) : void {
					if (tg.dragging) {
						tg.x = tg.stage.mouseX - tg.mx;
						if (tg.mode == "left" && tg.x + CORNER_OFFSET > vertx) {
							// prevent from moving to right side
							tg.x = vertx - CORNER_OFFSET - 1;
						}
						if (tg.x < tg.x1 + MINSIZE) {
							tg.x = tg.x1 + MINSIZE;
						}
						hsize = (tg.x + CORNER_OFFSET) - tg.x1;
						if (hsize < MINSIZE) {
							hsize = MINSIZE;
						}
						tg.y = tg.stage.mouseY - tg.my;
						if (tg.y > tg.y2 - MINSIZE) {
							tg.y = tg.y2 - MINSIZE;
						}
						vsize = tg.y2 - (tg.y - CORNER_OFFSET);
						if (vsize < MINSIZE) {
							vsize = MINSIZE;
						}
						if (tg.mode == "left") {
							sq1x = (tg.x + CORNER_OFFSET) - hsize;
							sq2x = vertx + vertx - sq1x - hsize;
						} else {
							sq2x = (tg.x + CORNER_OFFSET) - hsize;
							sq1x = vertx - (sq2x - vertx) - hsize;
						}
						// .y is common to both
						sq1y = tg.y - CORNER_OFFSET;
						sq2y = sq1y;
						// indicate that the stage should be updated on the next tick:
						update = true;
					}
				});
			})(corner_sprites[1]);
			(function(tg : Corner) : void {
				tg.addEventListener(MouseEvent.MOUSE_MOVE, function(e : MouseEvent) : void {
					if (tg.dragging) {
						tg.x = tg.stage.mouseX - tg.mx;
						if (tg.mode == "right" && tg.x - CORNER_OFFSET <= vertx) {
							// prevent from moving to left side
							tg.x = vertx + CORNER_OFFSET + 1;
						}
						if (tg.x > tg.x2 - MINSIZE) {
							tg.x = tg.x2 - MINSIZE;
						}
						hsize = tg.x2 - (tg.x - CORNER_OFFSET);
						if (hsize < MINSIZE) {
							hsize = MINSIZE;
						}
						tg.y = tg.stage.mouseY - tg.my;
						if (tg.y < tg.y1 + MINSIZE) {
							tg.y = tg.y1 + MINSIZE;
						}
						vsize = (tg.y + CORNER_OFFSET) - tg.y1;
						if (vsize < MINSIZE) {
							vsize = MINSIZE;
						}
						if (tg.mode == "left") {
							sq1x = tg.x - CORNER_OFFSET;
							sq2x = vertx + vertx - sq1x - hsize;
						} else {
							sq2x = tg.x - CORNER_OFFSET;
							sq1x = vertx - (sq2x - vertx) - hsize;
						}
						// .y is common to both
						sq1y = tg.y + CORNER_OFFSET - vsize;
						sq2y = sq1y;
						// indicate that the stage should be updated on the next tick:
						update = true;
					}
				});
			})(corner_sprites[2]);
			(function(tg : Corner) : void {
				tg.addEventListener(MouseEvent.MOUSE_MOVE, function(e : MouseEvent) : void {
					if (tg.dragging) {
						tg.x = tg.stage.mouseX - tg.mx;
						if (tg.mode == "left" && tg.x + CORNER_OFFSET > vertx) {
							// prevent from moving to right side
							tg.x = vertx - CORNER_OFFSET - 1;
						}
						if (tg.x < tg.x1 + MINSIZE) {
							tg.x = tg.x1 + MINSIZE;
						}
						hsize = (tg.x + CORNER_OFFSET) - tg.x1;
						if (hsize < MINSIZE) {
							hsize = MINSIZE;
						}
						tg.y = tg.stage.mouseY - tg.my;
						if (tg.y < tg.y1 + MINSIZE) {
							tg.y = tg.y1 + MINSIZE;
						}
						vsize = (tg.y + CORNER_OFFSET) - tg.y1;
						if (vsize < MINSIZE) {
							vsize = MINSIZE;
						}
						if (tg.mode == "left") {
							sq1x = (tg.x + CORNER_OFFSET) - hsize;
							sq2x = vertx + vertx - sq1x - hsize;
						} else {
							sq2x = (tg.x + CORNER_OFFSET) - hsize;
							sq1x = vertx - (sq2x - vertx) - hsize;
						}
						// .y is common to both
						sq1y = tg.y + CORNER_OFFSET - vsize;
						sq2y = sq1y;
						// indicate that the stage should be updated on the next tick:
						update = true;
					}
				});
			})(corner_sprites[3]);
			(function(tg : Corner) : void {
				tg.addEventListener(MouseEvent.MOUSE_MOVE, function(e : MouseEvent) : void {
					if (tg.dragging) {
						tg.x = tg.stage.mouseX - tg.mx;
						if (tg.mode == "right" && tg.x - CORNER_OFFSET < vertx) {
							// prevent from moving to left side
							tg.x = vertx + CORNER_OFFSET + 1;
						}
						if (tg.x > tg.x2 - MINSIZE) {
							tg.x = tg.x2 - MINSIZE;
						}
						hsize = tg.x2 - (tg.x - CORNER_OFFSET);
						if (hsize < MINSIZE) {
							hsize = MINSIZE;
						}
						tg.y = tg.stage.mouseY - tg.my;
						if (tg.y > tg.y2 - MINSIZE) {
							tg.y = tg.y2 - MINSIZE;
						}
						vsize = tg.y2 - (tg.y - CORNER_OFFSET);
						if (vsize < MINSIZE) {
							vsize = MINSIZE;
						}
						if (tg.mode == "left") {
							sq1x = tg.x - CORNER_OFFSET;
							sq2x = vertx + vertx - sq1x - hsize;
						} else {
							sq2x = tg.x - CORNER_OFFSET;
							sq1x = vertx - (sq2x - vertx) - hsize;
						}
						// .y is common to both
						sq1y = tg.y - CORNER_OFFSET;
						sq2y = sq1y;
						// indicate that the stage should be updated on the next tick:
						update = true;
					}
				});
			})(corner_sprites[4]);
			(function(tg : Corner) : void {
				tg.addEventListener(MouseEvent.MOUSE_MOVE, function(e : MouseEvent) : void {
					if (tg.dragging) {
						tg.x = tg.stage.mouseX - tg.mx;
						if (tg.mode == "left" && tg.x + CORNER_OFFSET > vertx) {
							// prevent from moving to right side
							tg.x = vertx - CORNER_OFFSET - 1;
						}
						if (tg.x < tg.x1 + MINSIZE) {
							tg.x = tg.x1 + MINSIZE;
						}
						hsize = (tg.x + CORNER_OFFSET) - tg.x1;
						if (hsize < MINSIZE) {
							hsize = MINSIZE;
						}
						tg.y = tg.stage.mouseY - tg.my;
						if (tg.y > tg.y2 - MINSIZE) {
							tg.y = tg.y2 - MINSIZE;
						}
						vsize = tg.y2 - (tg.y - CORNER_OFFSET);
						if (vsize < MINSIZE) {
							vsize = MINSIZE;
						}
						if (tg.mode == "left") {
							sq1x = (tg.x + CORNER_OFFSET) - hsize;
							sq2x = vertx + vertx - sq1x - hsize;
						} else {
							sq2x = (tg.x + CORNER_OFFSET) - hsize;
							sq1x = vertx - (sq2x - vertx) - hsize;
						}
						// .y is common to both
						sq1y = tg.y - CORNER_OFFSET;
						sq2y = sq1y;
						// indicate that the stage should be updated on the next tick:
						update = true;
					}
				});
			})(corner_sprites[5]);
			(function(tg : Corner) : void {
				tg.addEventListener(MouseEvent.MOUSE_MOVE, function(e : MouseEvent) : void {
					if (tg.dragging) {
						tg.x = tg.stage.mouseX - tg.mx;
						if (tg.mode == "right" && tg.x - CORNER_OFFSET <= vertx) {
							// prevent from moving to left side
							tg.x = vertx + CORNER_OFFSET + 1;
						}
						if (tg.x > tg.x2 - MINSIZE) {
							tg.x = tg.x2 - MINSIZE;
						}
						hsize = tg.x2 - (tg.x - CORNER_OFFSET);
						if (hsize < MINSIZE) {
							hsize = MINSIZE;
						}
						tg.y = tg.stage.mouseY - tg.my;
						if (tg.y < tg.y1 + MINSIZE) {
							tg.y = tg.y1 + MINSIZE;
						}
						vsize = (tg.y + CORNER_OFFSET) - tg.y1;
						if (vsize < MINSIZE) {
							vsize = MINSIZE;
						}
						if (tg.mode == "left") {
							sq1x = tg.x - CORNER_OFFSET;
							sq2x = vertx + vertx - sq1x - hsize;
						} else {
							sq2x = tg.x - CORNER_OFFSET;
							sq1x = vertx - (sq2x - vertx) - hsize;
						}
						// .y is common to both
						sq1y = tg.y + CORNER_OFFSET - vsize;
						sq2y = sq1y;
						// indicate that the stage should be updated on the next tick:
						update = true;
					}
				});
			})(corner_sprites[6]);
			(function(tg : Corner) : void {
				tg.addEventListener(MouseEvent.MOUSE_MOVE, function(e : MouseEvent) : void {
					if (tg.dragging) {
						tg.x = tg.stage.mouseX - tg.mx;
						if (tg.mode == "left" && tg.x + CORNER_OFFSET > vertx) {
							// prevent from moving to right side
							tg.x = vertx - CORNER_OFFSET - 1;
						}
						if (tg.x < tg.x1 + MINSIZE) {
							tg.x = tg.x1 + MINSIZE;
						}
						hsize = (tg.x + CORNER_OFFSET) - tg.x1;
						if (hsize < MINSIZE) {
							hsize = MINSIZE;
						}
						tg.y = tg.stage.mouseY - tg.my;
						if (tg.y < tg.y1 + MINSIZE) {
							tg.y = tg.y1 + MINSIZE;
						}
						vsize = (tg.y + CORNER_OFFSET) - tg.y1;
						if (vsize < MINSIZE) {
							vsize = MINSIZE;
						}
						if (tg.mode == "left") {
							sq1x = (tg.x + CORNER_OFFSET) - hsize;
							sq2x = vertx + vertx - sq1x - hsize;
						} else {
							sq2x = (tg.x + CORNER_OFFSET) - hsize;
							sq1x = vertx - (sq2x - vertx) - hsize;
						}
						// .y is common to both
						sq1y = tg.y + CORNER_OFFSET - vsize;
						sq2y = sq1y;
						// indicate that the stage should be updated on the next tick:
						update = true;
					}
				});
			})(corner_sprites[7]);
		}

		public function draw() : void {
			drawStereoscope();
		}

		public function drawStereoscope() : void {
			drawBackground();
			drawVertical();
			drawSquare(sq1, sq1x, sq1y);
			drawSquare(sq2, sq2x, sq2y);
			drawCorners();
		}

		public function drawBackground() : void {
			var g : Graphics = bg.graphics;
			g.clear();
			g.lineStyle(undefined);
			g.beginFill(BACKFILL, 0.75);
			g.drawRect(0, 0, stage.width, sq1y);
			g.drawRect(0, sq1y, sq1x, vsize);
			// g.drawRect(sq1x+hsize,sq1y,(vertx-sq1x-hsize)*2,vsize);
			g.drawRect(sq2x + hsize, sq1y, stage.width - (sq2x + hsize), vsize);
			g.drawRect(0, sq1y + vsize, stage.width, stage.height - vsize - sq1y);
		}

		public function drawVertical() : void {
			vert_sprite.x = vertx;
			var g : Graphics = vert_sprite.graphics;
			g.clear();
			if (!vert_sprite.over) {
				g.lineStyle(THICK, COLOR);
			} else {
				g.lineStyle(THICK, OVERCOLOR);
			}
			g.beginFill(MAINFILL, 0.1);
			g.drawRect(-(VERTWIDTH * .5), -(VERTHEIGHT * .5), VERTWIDTH, VERTHEIGHT);
			g.endFill();
			g.moveTo(0, -(VERTHEIGHT * .5));
			g.lineTo(0, -550);
			g.moveTo(0, (VERTHEIGHT * .5));
			g.lineTo(0, 550);
			g.moveTo(-(VERTWIDTH * .5), 0);
			g.lineTo(-(VERTWIDTH * .5), VERTWIDTH * .5);
			g.lineTo(-VERTWIDTH, 0);
			g.lineTo(-(VERTWIDTH * .5), -(VERTWIDTH * .5));
			g.lineTo(-(VERTWIDTH * .5), 0);
			g.moveTo((VERTWIDTH * .5), 0);
			g.lineTo((VERTWIDTH * .5), VERTWIDTH * .5);
			g.lineTo(VERTWIDTH, 0);
			g.lineTo((VERTWIDTH * .5), -(VERTWIDTH * .5));
			g.lineTo((VERTWIDTH * .5), 0);
		}

		public function drawCorners() : void {
			var x : Number = -1000;
			var y : Number = -1000;
			var i : Number, crnr : Corner;
			for (i = 0;i < 8;++i) {
				crnr = corner_sprites[i];
				crnr.graphics.clear();
				if (!crnr.over) {
					crnr.graphics.lineStyle(THICK, COLOR);
				} else {
					crnr.graphics.lineStyle(THICK, OVERCOLOR);
				}
				crnr.graphics.beginFill(MAINFILL, 0.1);
				crnr.graphics.drawRect(-CORNER_OFFSET, -CORNER_OFFSET, CORNER_OFFSET + CORNER_OFFSET, CORNER_OFFSET + CORNER_OFFSET);
				crnr.graphics.endFill();
				if (crnr.mysquare == sq1) {
					x = sq1x;
					y = sq1y;
				} else if (crnr.mysquare == sq2) {
					x = sq2x;
					y = sq2y;
				}
				crnr.x = x + CORNER_OFFSET + ((hsize - CORNER_OFFSET - CORNER_OFFSET) * crnr.xfactor);
				crnr.y = y + CORNER_OFFSET + ((vsize - CORNER_OFFSET - CORNER_OFFSET) * crnr.yfactor);
			}
		}

		public function drawSquare(square : Square, x : Number, y : Number) : void {
			var g : Graphics = square.graphics;
			var CROSSSIZE : Number = INSET;
			g.clear();
			if (square.over) {
				g.lineStyle(THICK, OVERCOLOR);
			} else {
				g.lineStyle(THICK, COLOR);
			}
			g.beginFill(MAINFILL, 0.1);
			g.drawRect(x, y, hsize, vsize);
			g.endFill();
			if (square.over) {
				CROSSSIZE = INSET * 2;
				g.moveTo(x - CROSSSIZE + hsize / 2, y - CROSSSIZE + vsize / 2);
				g.lineTo(x + CROSSSIZE + hsize / 2, y + CROSSSIZE + vsize / 2);
				g.moveTo(x + CROSSSIZE + hsize / 2, y - CROSSSIZE + vsize / 2);
				g.lineTo(x - CROSSSIZE + hsize / 2, y + CROSSSIZE + vsize / 2);
				// draw arrows
				g.moveTo(x - CROSSSIZE + hsize / 2, (y - CROSSSIZE + vsize / 2) + (CROSSSIZE / 2));
				g.lineTo(x - CROSSSIZE + hsize / 2, y - CROSSSIZE + vsize / 2);
				g.lineTo(x - CROSSSIZE + hsize / 2 + (CROSSSIZE / 2), y - CROSSSIZE + vsize / 2);
				g.moveTo(x + CROSSSIZE + hsize / 2, y + CROSSSIZE + vsize / 2 - (CROSSSIZE / 2));
				g.lineTo(x + CROSSSIZE + hsize / 2, y + CROSSSIZE + vsize / 2);
				g.lineTo(x + CROSSSIZE + hsize / 2 - (CROSSSIZE / 2), y + CROSSSIZE + vsize / 2);
				g.moveTo(x + CROSSSIZE + hsize / 2, y - CROSSSIZE + vsize / 2 + (CROSSSIZE / 2));
				g.lineTo(x + CROSSSIZE + hsize / 2, y - CROSSSIZE + vsize / 2);
				g.lineTo(x + CROSSSIZE + hsize / 2 - (CROSSSIZE / 2), y - CROSSSIZE + vsize / 2);
				g.moveTo(x - CROSSSIZE + hsize / 2, y + CROSSSIZE + vsize / 2 - (CROSSSIZE / 2));
				g.lineTo(x - CROSSSIZE + hsize / 2, y + CROSSSIZE + vsize / 2);
				g.lineTo(x - CROSSSIZE + hsize / 2 + (CROSSSIZE / 2), y + CROSSSIZE + vsize / 2);
			} else {
				g.lineStyle(THICK, COLOR);
				g.moveTo(x - CROSSSIZE + hsize / 2, y - CROSSSIZE + vsize / 2);
				g.lineTo(x + CROSSSIZE + hsize / 2, y + CROSSSIZE + vsize / 2);
				g.moveTo(x + CROSSSIZE + hsize / 2, y - CROSSSIZE + vsize / 2);
				g.lineTo(x - CROSSSIZE + hsize / 2, y + CROSSSIZE + vsize / 2);
			}
		}

		public function tick(e : TimerEvent) : void {
			// this set makes it so the stage only re-renders when an event handler indicates a change has happened.
			if (update) {
				draw();
				update = false;
				// only update once
				updatePreview();
				if (mode == "ANAGLYPH") {
					drawAnaglyph();
				}
			}
			if (mode == "GIF") {
				drawGIF();
			}
		}

		public function updatePreview() : void {
			// used to be change width/height of preview div
		}

		public function toggleMode(m : String) : void {
			trace(m);
			mode = m;
			if (m == "GIF") {
				toggleClip.anaClip.anaClipOff.visible = false;
				toggleClip.anaClip.anaBtn.visible = true;
				toggleClip.gifClip.gifBtn.visible = false;
				toggleClip.gifClip.gifClipOff.visible = true;
				if (speed == SLOWSPEED) {
					toggleClip.gifClip.slowClipOff.visible = true;
					toggleClip.gifClip.slowClip.visible = false;
				} else {
					toggleClip.gifClip.slowClipOff.visible = false;
					toggleClip.gifClip.slowClip.visible = true;
				}
				if (speed == MEDSPEED) {
					toggleClip.gifClip.medClipOff.visible = true;
					toggleClip.gifClip.medClip.visible = false;
				} else {
					toggleClip.gifClip.medClipOff.visible = false;
					toggleClip.gifClip.medClip.visible = true;
				}
				if (speed == FASTSPEED) {
					toggleClip.gifClip.fastClipOff.visible = true;
					toggleClip.gifClip.fastClip.visible = false;
				} else {
					toggleClip.gifClip.fastClipOff.visible = false;
					toggleClip.gifClip.fastClip.visible = true;
				}
			} else {
				toggleClip.anaClip.anaClipOff.visible = true;
				toggleClip.anaClip.anaBtn.visible = false;
				toggleClip.gifClip.gifBtn.visible = true;
				toggleClip.gifClip.gifClipOff.visible = false;
				toggleClip.gifClip.slowClip.visible = false;
				toggleClip.gifClip.medClip.visible = false;
				toggleClip.gifClip.fastClip.visible = false;
			}
			update = true;
		}

		public function drawGIF() : void {
			// get rid of anaglyph canvas in preview
			now = getTimer();
			if (now - lasttick >= speed) {
				lasttick = now;
				var data : BitmapData = new BitmapData(hsize, vsize, false, 0x000000);
				if (frame == 1) {
					// left
					data.copyPixels(bmp.bitmapData, new Rectangle(sq1x - OFFSET, sq1y, hsize, vsize), new Point());
					frame = 2;
				} else {
					// right
					data.copyPixels(bmp.bitmapData, new Rectangle(sq2x - OFFSET, sq2y, hsize, vsize), new Point());
					frame = 1;
				}
				processbmp.bitmapData = data;
				processbmp.x = Math.floor((400 - processbmp.width) * .5);
				processbmp.y = 10;
			}
		}

		public function drawAnaglyph() : void {
			// left = 0,255,255
			// right = 255,0,0

			// *** LEFT IMAGE
			// Get the image data
			var left : BitmapData = new BitmapData(hsize, vsize, false, 0x000000);
			left.copyPixels(bmp.bitmapData, new Rectangle(sq1x - OFFSET, sq1y, hsize, vsize), new Point());

			// *** RIGHT IMAGE
			// Get the image data
			var right : BitmapData = new BitmapData(hsize, vsize, false, 0x000000);
			right.copyPixels(bmp.bitmapData, new Rectangle(sq2x - OFFSET, sq2y, hsize, vsize), new Point());

			left.copyChannel(right, new Rectangle(0, 0, right.width, right.height), new Point(0, 0), BitmapDataChannel.RED, BitmapDataChannel.RED);

			processbmp.bitmapData = left;
			processbmp.x = Math.floor((400 - processbmp.width) * .5);
			processbmp.y = 10;
		}

		public function loadPhoto(str : String) : void {
			trace("photo");
			index = str;
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, handleImageLoad);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, handleImageError);

			var url : String = baseurl + "/getpixels/" + index + ".jpeg";
			var request : URLRequest = new URLRequest(url);
			var lc : LoaderContext = new LoaderContext();
			lc.checkPolicyFile = false;
			loader.load(request, lc);
			hiddenClip.addChild(loader);
		}

		public function changeSpeed(s : Number) : void {
			speed = s;
			trace(speed);
			toggleMode("GIF");
		}

		public function generate(e : MouseEvent) : void {
			trace("generating...");
			btnNext.enabled = false;
			generatingClip.visible = true;
			ExternalInterface.call("generateFromFlash", sq1x-OFFSET, sq1y, sq2x-OFFSET, sq2y, hsize, vsize, speed, index, mode);
		}

		public function handleImageLoad(e : Event) : void {
			trace("Loading image");
			// all elements have been downloaded
			// Set up the canvas
			bmp = Bitmap(loader.content);
			canvas.addChild(bmp);

			if (first) {
				first = false;
			}
			run();
			prepareInterface();
			// adding interaction
			addInteractivity();
			update = true;
		}

		// called if there is an error loading the image (usually due to a 404)
		public function handleImageError(e : IOErrorEvent) : void {
			trace("Error Loading Image : " + e.text);
		}
	}
}
