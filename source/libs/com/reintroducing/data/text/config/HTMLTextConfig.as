package com.reintroducing.data.text.config
{
	import com.reintroducing.data.base.ValueObject;

	import flash.text.AntiAliasType;
	import flash.text.TextFieldAutoSize;
	import flash.utils.getQualifiedClassName;

	/**
	 * Strongly typed value object for HTMLTextField usage in the TextManager.
	 * 
	 * @author Matt Przybylski [http://www.reintroducing.com]
 	 * @version 1.0
 	 */
	public class HTMLTextConfig extends ValueObject implements ITextConfig
	{
//- PRIVATE & PROTECTED VARIABLES -------------------------------------------------------------------------

		
		
//- PUBLIC & INTERNAL VARIABLES ---------------------------------------------------------------------------
		
		public var antiAliasType:String = AntiAliasType.ADVANCED;
		public var autoSize:String = TextFieldAutoSize.LEFT;
		public var selectable:Boolean = false;
		public var wordWrap:Boolean = true;
		public var multiline:Boolean = true;
		public var width:Number = 100;
		public var height:Number = 100;
		
//- CONSTRUCTOR	-------------------------------------------------------------------------------------------
	
		public function HTMLTextConfig()
		{
			super();
		}
		
//- PRIVATE & PROTECTED METHODS ---------------------------------------------------------------------------
		
		
		
//- PUBLIC & INTERNAL METHODS -----------------------------------------------------------------------------
	
		
	
//- EVENT HANDLERS ----------------------------------------------------------------------------------------
	
		
	
//- GETTERS & SETTERS -------------------------------------------------------------------------------------
	
		
	
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