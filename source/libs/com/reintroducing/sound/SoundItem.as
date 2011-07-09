package com.reintroducing.sound
{
	import com.greensock.TweenLite;
	import com.greensock.plugins.TweenPlugin;
	import com.greensock.plugins.VolumePlugin;
	import com.reintroducing.events.SoundManagerEvent;

	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * A class that acts as a holder for a sound to be used in the SoundManager.
	 * 
 	 * @author Matt Przybylski [http://www.reintroducing.com]
 	 * @version 1.4.2
 	 */
	public class SoundItem extends EventDispatcher
	{
//- PRIVATE & PROTECTED VARIABLES -------------------------------------------------------------------------

		private var _fadeTween:TweenLite;
		private var _volume:Number;		//- PUBLIC & INTERNAL VARIABLES ---------------------------------------------------------------------------				public var name:String;
		public var sound:Sound;		public var channel:SoundChannel;		public var position:int;		public var paused:Boolean;		public var savedVolume:Number;		public var startTime:Number;		public var loops:int;		public var pausedByAll:Boolean;		public var muted:Boolean;
		
//- CONSTRUCTOR	-------------------------------------------------------------------------------------------
	
		public function SoundItem():void		{			super();
			
			TweenPlugin.activate([VolumePlugin]);
			
			init();		}
		
//- PRIVATE & PROTECTED METHODS ---------------------------------------------------------------------------
		
		/**
		 *
		 */
		private function init():void
		{
			channel = new SoundChannel();
		}
		
		/**
		 * 
		 */
		private function fadeComplete($stopOnComplete:Boolean):void
		{
			if ($stopOnComplete) stop();
			
			dispatchEvent(new SoundManagerEvent(SoundManagerEvent.SOUND_ITEM_FADE_COMPLETE, this));
		}
		
//- PUBLIC & INTERNAL METHODS -----------------------------------------------------------------------------
	
		/**
		 * Plays the SoundItem.
		 * 
		 * @param $startTime The time, in milliseconds, to start the sound at (default: 0)
		 * @param $loops The number of times to loop (default: 0)
		 * @param $volume The volume to play the sound at (default: 1)
		 * @param $resumeTween If the fade tween should be resumed if it's currently running (default: true)
		 * 
		 * @return void
		 */
		public function play($startTime:Number = 0, $loops:int = 0, $volume:Number = 1, $resumeTween:Boolean = true):void		{			if (!paused) return;
			
			volume = $volume;
			startTime = $startTime;
			loops = $loops;
			paused = ($startTime == 0) ? true : false;
			
			if (!paused) position = startTime;
			
			channel = sound.play(position, loops, new SoundTransform(volume));
			channel.addEventListener(Event.SOUND_COMPLETE, handleSoundComplete);
			paused = false;
			
			if ($resumeTween && (fadeTween != null)) fadeTween.resume();		}
		
		/**
		 * Pauses the SoundItem.
		 * 
		 * @param $pauseTween If the fade tween should be paused if it's currently running (default: true)
		 * 
		 * @return void
		 */
		public function pause($pauseTween:Boolean = true):void
		{
			paused = true;
			position = channel.position;
			channel.stop();
			channel.removeEventListener(Event.SOUND_COMPLETE, handleSoundComplete);
			
			if ($pauseTween && (fadeTween != null)) fadeTween.pause();
		}
		
		/**
		 * Stops the SoundItem.
		 * 
		 * @return void
		 */
		public function stop():void
		{
			paused = true;
			channel.stop();
			channel.removeEventListener(Event.SOUND_COMPLETE, handleSoundComplete);
			position = channel.position;
			fadeTween = null;
		}
		
		/**
		 * Fades the SoundItem.
		 * 
		 * @param $volume The volume to fade to (default: 0)
		 * @param $fadeLength The time, in seconds, to fade over (default: 1)
		 * @param $stopOnComplete If the sound should be stopped after fading is complete (default: false)
		 */
		public function fade($volume:Number = 0, $fadeLength:Number = 1, $stopOnComplete:Boolean = false):void
		{
			fadeTween = TweenLite.to(channel, $fadeLength, {volume: $volume, onComplete: fadeComplete, onCompleteParams: [$stopOnComplete]});
		}
		
		/**
		 * Sets the volume of the SoundItem.
		 * 
		 * @param $volume The volume to set on the sound
		 * 
		 * @return void
		 */
		public function setVolume($volume:Number):void
		{
			var curTransform:SoundTransform = channel.soundTransform;
			curTransform.volume = $volume;
			channel.soundTransform = curTransform;
			
			_volume = $volume;
		}
		
		/**
		 * Clears and makes the SoundItem available for garbage collection.
		 * 
		 * @return void
		 */
		public function destroy():void
		{
			channel.removeEventListener(Event.SOUND_COMPLETE, handleSoundComplete);
			channel = null;
			fadeTween = null;
		}
	
//- EVENT HANDLERS ----------------------------------------------------------------------------------------
	
		/**
		 *
		 */
		private function handleSoundComplete($evt:Event):void
		{
			stop();
			
			dispatchEvent(new SoundManagerEvent(SoundManagerEvent.SOUND_ITEM_PLAY_COMPLETE, this));
		}
	
//- GETTERS & SETTERS -------------------------------------------------------------------------------------
	
		/**
		 * Returns the volume of the Sounditem.
		 * 
		 * @return Number
		 */
		public function get volume():Number
		{
		    return channel.soundTransform.volume;
		}
		
		/**
		 * Sets the volume of the SoundItem.
		 * 
		 * @param $val The volume to set
		 * 
		 * @return void
		 */
		public function set volume($val:Number):void
		{
			setVolume($val);
		}
		
		/**		 * Returns the instance of the fading tween.
		 * 
		 * @return TweenLite		 */		public function get fadeTween():TweenLite		{		    return _fadeTween;		}				/**		 * Sets the instance of the fading tween.
		 * 
		 * @param $val The TweenLite instance to create
		 * 
		 * @return void		 */		public function set fadeTween($val:TweenLite):void		{			if ($val == null) TweenLite.killTweensOf(this);						_fadeTween = $val;		}
	
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