package com.reintroducing.utils
{
	import com.reintroducing.data.utils.ExternalInterfaceMethod;
	import flash.external.ExternalInterface;
	import flash.utils.clearInterval;
	import flash.utils.getQualifiedClassName;
	import flash.utils.setInterval;

	/**
	 * Utility to buffer outgoing ExternalInterface calls. Simultaneous calls get dropped if they aren't buffered. It seems both Firefox and IE's script engine gets overloaded and either drops calls or
	 * throws a JavaScript error. This buffer ensures the script engines only get one call at a time.
	 * 
	 * <pre>
	 * 		var eiMethod:ExternalInterfaceMethod = new ExternalInterfaceMethod();
	 * 		eiMethod.methodName = "jsMethodName";
	 * 		eiMethod.methodParameters = {argA: "blah", argB: "merp", argC: "DOH"};
	 * 			 * 		ExternalInterfaceManager.getInstance().call(eiMethod);
	 * </pre>
	 * 
	 * @author Scott Morgan for Yahoo! Maps AS3 Communication Kit (2007)
	 * @author Matt Przybylski [http://www.reintroducing.com] - Modified to use strongly typed ExternalInterfaceMethod value object
	 * @version 1.0
	 */
	public class ExternalInterfaceManager
	{
//- PRIVATE & PROTECTED VARIABLES -------------------------------------------------------------------------

		// singleton instance
		private static var _instance:ExternalInterfaceManager;
		private static var _allowInstance:Boolean;
		
		private var methodQueue:Array = [];
		private var methodCallInterval:Number;
		
//- PUBLIC & INTERNAL VARIABLES ---------------------------------------------------------------------------
		
		
		
//- CONSTRUCTOR	-------------------------------------------------------------------------------------------
	
		// singleton instance of ExternalInterfaceManager
		public static function getInstance():ExternalInterfaceManager 
		{
			if (_instance == null)
			{
				_allowInstance = true;
				_instance = new ExternalInterfaceManager();
				_allowInstance = false;
			}
			
			return _instance;
		}
		
		public function ExternalInterfaceManager() 
		{
			if (!_allowInstance)
			{
				throw new Error("Error: Use ExternalInterfaceManager.getInstance() instead of the new keyword.");
			}
		}
		
//- PRIVATE & PROTECTED METHODS ---------------------------------------------------------------------------
		
		/**
		 * Called every 50 milliseconds until the methodQueue array is empty. This method sends the first method listed in the methodQueue array to the
		 * ExternalInterface.call method.
		 *
		 * @return void
		 */
		private function methodChurn():void 
		{
			var eiMethod:ExternalInterfaceMethod = (methodQueue[0] as ExternalInterfaceMethod);
			
			if (eiMethod.methodName) ExternalInterface.call(eiMethod.methodName, eiMethod.methodParameters);
			
			methodQueue.shift();
			
			if (methodQueue.length == 0)
			{
				clearInterval(methodCallInterval);
				
				methodCallInterval = undefined;
			}
		}
		
//- PUBLIC & INTERNAL METHODS -----------------------------------------------------------------------------
	
		/**
		 * Adds calls to the methodQueue array. If the length of the methodQueue array is greater than 0 the methodChurn interval is kicked off and runs every 50
		 * milliseconds until the methodQueue's length is 0 at which point the interval is cleared.
		 *
		 * @param $eiMethod The ExternalInterfaceMethod object to send to the queue.
		 * 
		 * @return void
		 */
		public function call($eiMethod:ExternalInterfaceMethod):void 
		{
			methodQueue.push($eiMethod);
			
			if (isNaN(methodCallInterval) || methodCallInterval == 0) methodCallInterval = setInterval(methodChurn, 50);
		}
	
//- EVENT HANDLERS ----------------------------------------------------------------------------------------
	
		
	
//- GETTERS & SETTERS -------------------------------------------------------------------------------------
	
		
	
//- HELPERS -----------------------------------------------------------------------------------------------
	
		/**
		 * @private
		 */
		public function toString():String
		{
			return getQualifiedClassName(this);
		}
	
//- END CLASS ---------------------------------------------------------------------------------------------
	}
}