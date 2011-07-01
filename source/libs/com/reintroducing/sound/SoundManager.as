package com.reintroducing.sound
{
	import com.reintroducing.events.SoundManagerEvent;

	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.media.Sound;
	import flash.media.SoundLoaderContext;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * The SoundManager is a singleton that allows you to have various ways to control sounds in your project.
	 * <p />
	 * The SoundManager can load external sounds, play sounds loaded through an asset loader, or library sounds, 
	 * pause/mute/stop/control volume for one or more sounds at a time, fade sounds up or down, and allows additional 
	 * control of sounds not readily available through the default classes.
	 * <p />
	 * The supplementary SoundItem class is dependent on TweenLite (http://www.tweenlite.com) to aid in easily fading the volume of the sound.
	 * 
	 * @author Matt Przybylski [http://www.reintroducing.com]
	 * @version 1.4.1
	 * 
	 * VERSION HISTORY:
	 *
	 * 1.4.1
	 * 		- REALLY fixed the muteAllSouns() method this time :) (thanks Ben Reynhart for pointing it out)
	 * 
	 * 1.4
	 * 		- General refactoring.
	 * 		
	 * 		- Added areAllMuted getter.  Fixed bug where if muteAllSounds() was called, playing a sound after that caused it
	 * 		  to play rather than stay muted.
	 * 		  
	 * 		- Fixed bug where calling muteAllSounds() didn't mute sounds that were being tweened at the same time (thanks Milan Orszagh).
	 * 		
	 * 		- Reverted to TweenLite for default fading behavior.
	 * 		
	 * 		- Reconfigured SoundItem to not extend sound and be its own object so that we can add preloaded sounds without hassle.
	 * 		
	 * 		- Added addPreloadedSound() method to add sounds that are loaded by an external loading system (thanks Nuajan for the idea).
	 * 		
	 * 		- Renamed events being fired by SoundManagerEvent to be more appropriate with what's happening.
	 * 		
	 * 		- Added SoundManagerEvent.SOUND_ITEM_PLAY_COMPLETE event.
	 * 		
	 * 		- Added a destroy() method to SoundItem to clean up for garbage collection.
	 *
	 * 1.3
	 * 		- Added the new SoundItem class so that each sound is strongly typed rather than being a generic Object.
	 * 		  When using sounds in your library, your sound MUST extend com.reintroducing.sound.SoundItem and NOT
	 * 		  flash.media.Sound.  Set this as the Base class in the properties panel for each library sound.
	 * 		
	 * 		- Added the getSoundItem() method and removed getSoundObject() method in favor of using the new SoundItem class.
	 * 		
	 * 		- Added the SoundManagerEvent and set the manager to fire off appropriate events.
	 * 		
	 * 		- Changed to TweenMax for default fading behavior.
	 * 		 
	 * 1.2
	 * 		- Removed ability to play the sound again if it is already playing (causes conflict with stopAllSounds). 
	 * 		  To play the same sound at the same time, add the sound under a differnet name (thanks Yu-Chung Chen).
	 * 		  
	 * 		- Fixed bug where playSound() wouldn't play from specified position if the sound was paused (thanks Yu-Chung Chen). 
	 * 		
	 * 1.1
	 * 		- Fixed bug where calling playSound() on a sound that was muted by muteAllSounds() was causing it to play.
	 * 		  Use unmuteAllSounds() to resume playback of muted sounds.
	 */
	public class SoundManager extends EventDispatcher
	{
//- PRIVATE & PROTECTED VARIABLES -------------------------------------------------------------------------

		// singleton instance
		private static var _instance:SoundManager;
		private static var _allowInstance:Boolean;
		
		private var _soundsDict:Dictionary;
		private var _sounds:Array;
		private var _areAllMuted:Boolean;
		private var _tempExternalSoundItem:SoundItem;
		
//- PUBLIC & INTERNAL VARIABLES ---------------------------------------------------------------------------
		
		
		
//- CONSTRUCTOR	-------------------------------------------------------------------------------------------
	
		// singleton instance of SoundManager
		public static function getInstance():SoundManager 
		{
			if (_instance == null)
			{
				_allowInstance = true;
				_instance = new SoundManager();
				_allowInstance = false;
			}
			
			return _instance;
		}
		
		public function SoundManager() 
		{
			this._soundsDict = new Dictionary(true);
			this._sounds = [];
			
			if (!_allowInstance)
			{
				throw new Error("Error: Use SoundManager.getInstance() instead of the new keyword.");
			}
		}
		
//- PRIVATE & PROTECTED METHODS ---------------------------------------------------------------------------
		
		/**
		 *
		 */
		private function addSound($linkageID:*, $preloadedSound:Sound, $path:String, $name:String, $buffer:Number = 1000, $checkPolicyFile:Boolean = false):Boolean
		{
			// check to see if sound already exists by the specified name
			var len:int = _sounds.length;
			
			for (var i:int = 0; i < len; i++)
			{
				if ((_sounds[i] as SoundItem).name == $name) return false;
			}
			
			// sound doesn't exist yet, go ahead and create it
			var si:SoundItem = new SoundItem();
			
			if ($linkageID == null)
			{
				if ($preloadedSound == null)
				{
					// adding external sound
					si.sound = new Sound(new URLRequest($path), new SoundLoaderContext($buffer, $checkPolicyFile));
					si.sound.addEventListener(IOErrorEvent.IO_ERROR, onSoundLoadError);
					si.sound.addEventListener(ProgressEvent.PROGRESS, onSoundLoadProgress);
					si.sound.addEventListener(Event.COMPLETE, onSoundLoadComplete);
					
					_tempExternalSoundItem = si;
				}
				else
				{
					// adding a preloaded sound
					si.sound = $preloadedSound;
				}
			}
			else
			{
				// adding library sound
				si.sound = new $linkageID;
			}
			
			si.name = $name;
			si.position = 0;
			si.paused = true;
			si.volume = (_areAllMuted) ? 0 : 1;
			si.savedVolume = si.volume;
			si.startTime = 0;
			si.loops = 0;
			si.pausedByAll = false;
			si.muted = _areAllMuted;
			si.addEventListener(SoundManagerEvent.SOUND_ITEM_PLAY_COMPLETE, handleSoundPlayComplete);
			
			_soundsDict[$name] = si;
			_sounds.push(si);
			
			dispatchEvent(new SoundManagerEvent(SoundManagerEvent.SOUND_ITEM_ADDED, si));
			
			return true;
		}
		
//- PUBLIC & INTERNAL METHODS -----------------------------------------------------------------------------
	
		/**
		 * Adds a sound from the library to the sounds dictionary for playing in the future.
		 * 
		 * @param $linkageID The class name of the library symbol that was exported for AS
		 * @param $name The string identifier of the sound to be used when calling other methods on the sound
		 * 
		 * @return Boolean A boolean value representing if the sound was added successfully
		 */
		public function addLibrarySound($linkageID:*, $name:String):Boolean
		{
			return addSound($linkageID, null, "", $name);
		}
		
		/**
		 * Adds an external sound to the sounds dictionary for playing in the future.
		 * 
		 * @param $path A string representing the path where the sound is on the server
		 * @param $name The string identifier of the sound to be used when calling other methods on the sound
		 * @param $buffer The number, in milliseconds, to buffer the sound before you can play it (default: 1000)
		 * @param $checkPolicyFile A boolean that determines whether Flash Player should try to download a cross-domain policy file from the loaded sound's server before beginning to load the sound (default: false) 
		 * 
		 * @return Boolean A boolean value representing if the sound was added successfully
		 */
		public function addExternalSound($path:String, $name:String, $buffer:Number = 1000, $checkPolicyFile:Boolean = false):Boolean
		{
			return addSound(null, null, $path, $name, $buffer, $checkPolicyFile);
		}
		
		/**
		 * Adds a sound that was preloaded by an external library to the sounds dictionary for playing in the future.
		 * 
		 * @param $sound The sound object that was preloaded
		 * @param $name The string identifier of the sound to be used when calling other methods on the sound
		 * 
		 * @return Boolean A boolean value representing if the sound was added successfully
		 */
		public function addPreloadedSound($sound:Sound, $name:String):Boolean
		{
			return addSound(null, $sound, "", $name);
		}
		
		/**
		 * Removes a sound from the sound dictionary.  After calling this, the sound will not be available until it is re-added.
		 * 
		 * @param $name The string identifier of the sound to remove
		 * 
		 * @return void
		 */
		public function removeSound($name:String):void
		{
			var len:int = _sounds.length;
			var si:SoundItem;
			
			for (var i:int = 0; i < len; i++)
			{
				si = (_sounds[i] as SoundItem);
				
				if (si.name == $name)
				{
					si.sound.removeEventListener(IOErrorEvent.IO_ERROR, onSoundLoadError);
					si.sound.removeEventListener(ProgressEvent.PROGRESS, onSoundLoadProgress);
					si.sound.removeEventListener(Event.COMPLETE, onSoundLoadComplete);
					si.removeEventListener(SoundManagerEvent.SOUND_ITEM_PLAY_COMPLETE, handleSoundPlayComplete);
					si.destroy();
					
					_sounds.splice(i, 1);
					
					break;
				}
			}
			
			dispatchEvent(new SoundManagerEvent(SoundManagerEvent.SOUND_ITEM_REMOVED, (_soundsDict[$name] as SoundItem)));
			
			delete (_soundsDict[$name] as SoundItem);
		}
		
		/**
		 * Removes all sounds from the sound dictionary.
		 * 
		 * @return void
		 */
		public function removeAllSounds():void
		{
			var len:int = _sounds.length;
			var si:SoundItem;
			
			for (var i:int = 0; i < len; i++)
			{
				si = (_sounds[i] as SoundItem);
				si.sound.removeEventListener(IOErrorEvent.IO_ERROR, onSoundLoadError);
				si.sound.removeEventListener(ProgressEvent.PROGRESS, onSoundLoadProgress);
				si.sound.removeEventListener(Event.COMPLETE, onSoundLoadComplete);
			}
			
			_sounds = [];
			_soundsDict = new Dictionary(true);
			
			dispatchEvent(new SoundManagerEvent(SoundManagerEvent.REMOVED_ALL));
		}

		/**
		 * Plays or resumes a sound from the sound dictionary with the specified name.  If the sounds in the dictionary were muted by 
		 * the muteAllSounds() method, no sounds are played until unmuteAllSounds() is called.
		 * 
		 * @param $name The string identifier of the sound to play
		 * @param $volume A number from 0 to 1 representing the volume at which to play the sound (default: 1)
		 * @param $startTime A number (in milliseconds) representing the time to start playing the sound at (default: 0)
		 * @param $loops An integer representing the number of times to loop the sound (default: 0)
		 * @param $resumeTween A boolean that indicates if a faded sound's volume should resume from the last saved state (default: true)
		 * 
		 * @return void
		 */
		public function playSound($name:String, $volume:Number = 1, $startTime:Number = 0, $loops:int = 0, $resumeTween:Boolean = true):void
		{
			var si:SoundItem = (_soundsDict[$name] as SoundItem);
			var volume:Number = (_areAllMuted) ? 0 : $volume;
			
			si.muted = _areAllMuted;
			si.savedVolume = $volume;
			si.play($startTime, $loops, volume, $resumeTween);
			
			dispatchEvent(new SoundManagerEvent(SoundManagerEvent.SOUND_ITEM_PLAY_START, si));
		}
		
		/**
		 * Pauses the specified sound.
		 * 
		 * @param $name The string identifier of the sound
		 * @param $pauseTween A boolean that either pauses the fadeTween or allows it to continue (default: true)
		 * 
		 * @return void
		 */
		public function pauseSound($name:String, $pauseTween:Boolean = true):void
		{
			var si:SoundItem = (_soundsDict[$name] as SoundItem);
			si.pause($pauseTween);
			
			dispatchEvent(new SoundManagerEvent(SoundManagerEvent.SOUND_ITEM_PAUSE, si));
		}
		
		/**
		 * Stops the specified sound.
		 * 
		 * @param $name The string identifier of the sound
		 * 
		 * @return void
		 */
		public function stopSound($name:String):void
		{
			var si:SoundItem = (_soundsDict[$name] as SoundItem);
			si.stop();
			
			dispatchEvent(new SoundManagerEvent(SoundManagerEvent.SOUND_ITEM_STOP, si));
		}
		
		/**
		 * Plays all the sounds that are in the sound dictionary.
		 * 
		 * @param $resumeTweens A boolean that resumes all unfinished fade tweens (default: true)
		 * @param $useCurrentlyPlayingOnly A boolean that only plays the sounds which were currently playing before a pauseAllSounds() or stopAllSounds() call (default: false)
		 * 
		 * @return void
		 */
		public function playAllSounds($resumeTweens:Boolean = true, $useCurrentlyPlayingOnly:Boolean = false):void
		{
			var len:int = _sounds.length;
			
			for (var i:int = 0; i < len; i++)
			{
				var id:String = (_sounds[i] as SoundItem).name;
				
				if ($useCurrentlyPlayingOnly)
				{
					if ((_soundsDict[id] as SoundItem).pausedByAll)
					{
						(_soundsDict[id] as SoundItem).pausedByAll = false;
						playSound(id, (_soundsDict[id] as SoundItem).volume, 0, 0, $resumeTweens);
					}
				}
				else
				{
					playSound(id, (_soundsDict[id] as SoundItem).volume, 0, 0, $resumeTweens);
				}
			}
			
			dispatchEvent(new SoundManagerEvent(SoundManagerEvent.PLAY_ALL));
		}
		
		/**
		 * Pauses all the sounds that are in the sound dictionary.
		 * 
		 * @param $pauseTweens A boolean that either pauses each SoundItem's fadeTween or allows them to continue (default: true)
		 * @param $useCurrentlyPlayingOnly A boolean that only pauses the sounds which are currently playing (default: true)
		 * 
		 * @return void
		 */
		public function pauseAllSounds($pauseTweens:Boolean = true, $useCurrentlyPlayingOnly:Boolean = true):void
		{
			var len:int = _sounds.length;
			
			for (var i:int = 0; i < len; i++)
			{
				var id:String = (_sounds[i] as SoundItem).name;
				
				if ($useCurrentlyPlayingOnly)
				{
					if (!(_soundsDict[id] as SoundItem).paused)
					{
						(_soundsDict[id] as SoundItem).pausedByAll = true;
						pauseSound(id, $pauseTweens);
					}
				}
				else
				{
					pauseSound(id, $pauseTweens);
				}
			}
			
			dispatchEvent(new SoundManagerEvent(SoundManagerEvent.PAUSE_ALL));
		}
		
		/**
		 * Stops all the sounds that are in the sound dictionary.
		 * 
		 * @param $useCurrentlyPlayingOnly A boolean that only stops the sounds which are currently playing (default: true)
		 * 
		 * @return void
		 */
		public function stopAllSounds($useCurrentlyPlayingOnly:Boolean = true):void
		{
			var len:int = _sounds.length;
			
			for (var i:int = 0; i < len; i++)
			{
				var id:String = (_sounds[i] as SoundItem).name;
				
				if ($useCurrentlyPlayingOnly)
				{
					if (!(_soundsDict[id] as SoundItem).paused)
					{
						(_soundsDict[id] as SoundItem).pausedByAll = true;
						stopSound(id);
					}
				}
				else
				{
					stopSound(id);
				}
			}
			
			dispatchEvent(new SoundManagerEvent(SoundManagerEvent.STOP_ALL));
		}
		
		/**
		 * Fades the sound to the specified volume over the specified amount of time.
		 * 
		 * @param $name The string identifier of the sound
		 * @param $targVolume The target volume to fade to, between 0 and 1 (default: 0)
		 * @param $fadeLength The time to fade over, in seconds (default: 1)
		 * @param $stopOnComplete Added by Danny Miller from K2xL, stops the sound once the fade is done if set to true
		 * 
		 * @return void
		 */
		public function fadeSound($name:String, $targVolume:Number = 0, $fadeLength:Number = 1, $stopOnComplete:Boolean = false):void
		{
			var si:SoundItem = (_soundsDict[$name] as SoundItem);
			si.addEventListener(SoundManagerEvent.SOUND_ITEM_FADE_COMPLETE, handleFadeComplete);
			si.fade($targVolume, $fadeLength, $stopOnComplete);
			
			dispatchEvent(new SoundManagerEvent(SoundManagerEvent.SOUND_ITEM_FADE, si));
		}
		
		/**
		 * Mutes the volume for all sounds in the sound dictionary.
		 * 
		 * @return void
		 */
		public function muteAllSounds():void
		{
			_areAllMuted = true;
			
			var len:int = _sounds.length;
			var id:String;
			var si:SoundItem;
			
			for (var i:int = 0; i < len; i++)
			{
				id = (_sounds[i] as SoundItem).name;
				si = (_soundsDict[id] as SoundItem);
				si.savedVolume = si.channel.soundTransform.volume;
				si.muted = true;
				
				setSoundVolume(id, 0);
			}
			
			dispatchEvent(new SoundManagerEvent(SoundManagerEvent.MUTE_ALL));
		}
		
		/**
		 * Resets the volume to their original setting for all sounds in the sound dictionary.
		 * 
		 * @return void
		 */
		public function unmuteAllSounds():void
		{
			_areAllMuted = false;
			
			var len:int = _sounds.length;
			var id:String;
			var si:SoundItem;
			
			for (var i:int = 0; i < len; i++)
			{
				id = (_sounds[i] as SoundItem).name;
				si = (_soundsDict[id] as SoundItem);
				si.muted = false;
				
				setSoundVolume(id, si.savedVolume);
			}
			
			dispatchEvent(new SoundManagerEvent(SoundManagerEvent.UNMUTE_ALL));
		}
		
		/**
		 * Sets the volume of the specified sound.
		 * 
		 * @param $name The string identifier of the sound
		 * @param $volume The volume, between 0 and 1, to set the sound to
		 * 
		 * @return void
		 */
		public function setSoundVolume($name:String, $volume:Number):void
		{
			(_soundsDict[$name] as SoundItem).setVolume($volume);
		}
		
		/**
		 * Gets the volume of the specified sound.
		 * 
		 * @param $name The string identifier of the sound
		 * 
		 * @return Number The current volume of the sound
		 */
		public function getSoundVolume($name:String):Number
		{
			return (_soundsDict[$name] as SoundItem).channel.soundTransform.volume;
		}
		
		/**
		 * Gets the position of the specified sound.
		 * 
		 * @param $name The string identifier of the sound
		 * 
		 * @return Number The current position of the sound, in milliseconds
		 */
		public function getSoundPosition($name:String):Number
		{
			return (_soundsDict[$name] as SoundItem).channel.position;
		}
		
		/**
		 * Gets the duration of the specified sound.
		 * 
		 * @param $name The string identifier of the sound
		 * 
		 * @return Number The length of the sound, in milliseconds
		 */
		public function getSoundDuration($name:String):Number
		{
			return (_soundsDict[$name] as SoundItem).sound.length;
		}
		
		/**
		 * Gets the SoundItem instance of the specified sound.
		 * 
		 * @param $name The string identifier of the SoundItem
		 * 
		 * @return SoundItem The SoundItem
		 */
		public function getSoundItem($name:String):SoundItem
		{
			return (_soundsDict[$name] as SoundItem);
		}
		
		/**
		 * Identifies if the sound is paused or not.
		 * 
		 * @param $name The string identifier of the sound
		 * 
		 * @return Boolean The boolean value of paused or not paused
		 */
		public function isSoundPaused($name:String):Boolean
		{
			return (_soundsDict[$name] as SoundItem).paused;
		}
		
		/**
		 * Identifies if the sound was paused or stopped by calling the stopAllSounds() or pauseAllSounds() methods.
		 * 
		 * @param $name The string identifier of the sound
		 * 
		 * @return Number The boolean value of pausedByAll or not pausedByAll
		 */
		public function isSoundPausedByAll($name:String):Boolean
		{
			return (_soundsDict[$name] as SoundItem).pausedByAll;
		}
	
//- EVENT HANDLERS ----------------------------------------------------------------------------------------
	
		/**
		 * Dispatched when an external sound can't load and produces an error.
		 */
		private function onSoundLoadError($evt:IOErrorEvent):void
		{
			_tempExternalSoundItem = null;
			
			dispatchEvent(new SoundManagerEvent(SoundManagerEvent.SOUND_ITEM_LOAD_ERROR));
		}
		
		/**
		 * Dispatched when an external sound is loading.
		 */
		private function onSoundLoadProgress($evt:ProgressEvent):void
		{
			var percent:uint = Math.round(100 * ($evt.bytesLoaded / $evt.bytesTotal));
			var snd:Sound = ($evt.target as Sound);
			var duration:Number = 0;
			
			if (snd && snd.length > 0)
			{
			    duration = ((snd.bytesTotal / (snd.bytesLoaded / snd.length)) * .001);
			}
			
			dispatchEvent(new SoundManagerEvent(SoundManagerEvent.SOUND_ITEM_LOAD_PROGRESS, _tempExternalSoundItem, duration, percent));
		}
		
		/**
		 * Dispatched when an external sound is fully loaded.
		 */
		private function onSoundLoadComplete($evt:Event):void
		{
			var snd:Sound = ($evt.target as Sound);
			var duration:Number = (snd.length * .001);
			
			dispatchEvent(new SoundManagerEvent(SoundManagerEvent.SOUND_ITEM_LOAD_COMPLETE, _tempExternalSoundItem, duration));
			
			_tempExternalSoundItem = null;
		}
		
		/**
		 * Dispatched once a sound's fadeTween is completed if the sound was called to fade.
		 */
		private function handleFadeComplete($evt:SoundManagerEvent):void
		{
			dispatchEvent($evt);
			
			var si:SoundItem = $evt.soundItem;
			si.removeEventListener(SoundManagerEvent.SOUND_ITEM_FADE_COMPLETE, handleFadeComplete);
		}
		
		/**
		 * Dispatched when a SoundItem has finished playback.
		 */
		private function handleSoundPlayComplete($evt:SoundManagerEvent):void
		{
			dispatchEvent($evt);
		}
	
//- GETTERS & SETTERS -------------------------------------------------------------------------------------
		
		/**
		 * Returns the sounds Array that's currently in the SoundManager.
		 * 
		 * @return Array
		 */
		public function get sounds():Array
		{
		    return _sounds;
		}
		
		/**
		 * Returns if the sounds in the SoundManager are all muted.
		 * 
		 * @return Boolean
		 */
		public function get areAllMuted():Boolean
		{
		    return _areAllMuted;
		}
	
//- HELPERS -----------------------------------------------------------------------------------------------
	
		/**
		 * @private
		 */
		override public function toString():String
		{
			return getQualifiedClassName(this);
		}
	
//- END CLASS ---------------------------------------------------------------------------------------------
	}
}