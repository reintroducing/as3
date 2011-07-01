package com.reintroducing.mouse
{
	import com.reintroducing.events.MouseIdleMonitorEvent;

	import flash.display.Stage;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;

	/**
	 * A small utility class that allows you to see if a user has been inactive with the mouse.  The class will dispatch a custom MouseIdleMonitorEvent
	 * with a params object that contains the time the user has been idle, in milliseconds.
	 * 
	 * @author Matt Przybylski [http://www.reintroducing.com]
	 * @version 1.0
	 */
	public class MouseIdleMonitor extends EventDispatcher
	{
//- PRIVATE & PROTECTED VARIABLES -------------------------------------------------------------------------

		private var _stage:Stage;
		private var _inactiveTime:int;
		private var _timer:Timer;
		private var _idleTime:int;
		private var _isMouseActive:Boolean;
		
//- PUBLIC & INTERNAL VARIABLES ---------------------------------------------------------------------------
		
		
		
//- CONSTRUCTOR	-------------------------------------------------------------------------------------------
		
		/**
		 * Creates an instance of hte MouseIdleMonitor class.  
		 * 
		 * <p>
		 * The class will dispatch two events:
		 * <ul>
		 * <li>MouseIdleMonitorEvent.MOUSE_ACTIVE: Dispatched when the mouse becomes active, repeatedly on MOUSE_MOVE</li>
		 * <li>MouseIdleMonitorEvent.MOUSE_IDLE: Dispatched when the mouse becomes inactive, idleTime param holds idle time</li>
		 * </ul>
		 * </p>
		 * 
		 * @param $stage The stage object to use for the mouse tracking
		 * @param $inactiveTime The time, in milliseconds, to check if the user is active or not (default: 1000)
		 * 
		 * @return void
		 */
		public function MouseIdleMonitor($stage:Stage, $inactiveTime:int = 1000)
		{
			super();
			
			_stage = $stage;
			_inactiveTime = $inactiveTime;
			_timer = new Timer(_inactiveTime);
		}
		
//- PRIVATE & PROTECTED METHODS ---------------------------------------------------------------------------
		
		
		
//- PUBLIC & INTERNAL METHODS -----------------------------------------------------------------------------
		
		/**
		 * Starts the MouseIdleMonitor and allows it to check for mouse inactivity.
		 * 
		 * @return void
		 */
		public function start():void
		{
			_stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			_timer.addEventListener(TimerEvent.TIMER, onTimer);
			
			_timer.start();
		}
		
		/**
		 * Stops the MouseIdleMonitor from checking for mouse inactivity.
		 * 
		 * @return void
		 */
		public function stop():void
		{
			_idleTime = 0;
			_timer.reset();
			
			_stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			_timer.removeEventListener(TimerEvent.TIMER, onTimer);
		}
	
//- EVENT HANDLERS ----------------------------------------------------------------------------------------
	
		/**
		 * Reset the timer if the mouse moves, user is active.
		 */
		private function onMouseMove($evt:MouseEvent):void
		{
			_isMouseActive = true;
			_idleTime = 0;
			_timer.reset();
			_timer.start();
			
			dispatchEvent(new MouseIdleMonitorEvent(MouseIdleMonitorEvent.MOUSE_ACTIVE));
		}
		
		/**
		 * Runs if the user is inactive, sets the idle time.
		 */
		private function onTimer($evt:TimerEvent):void
		{
			_isMouseActive = false;
			_idleTime += _inactiveTime;
			
			dispatchEvent(new MouseIdleMonitorEvent(MouseIdleMonitorEvent.MOUSE_IDLE, _idleTime));
		}
	
//- GETTERS & SETTERS -------------------------------------------------------------------------------------
		
		/**
		 * Returns a boolean value that specifies if the mouse is active or not.
		 * 
		 * @return Boolean
		 */
		public function get isMouseActive():Boolean
		{
		    return _isMouseActive;
		}
		
		/**
		 * Returns an integer representing the amount of time the user's mouse has been inactive, in milliseconds
		 * 
		 * @return int
		 */
		public function get idleTime():int
		{
		    return _idleTime;
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