package com.reintroducing.utils
		 * Traces out all the properties as provided by describeType.
		 */
		public static function describe($o:*, $type:String = "variable"):void
		{
			var props:XMLList = ($type == "variable") ? describeType($o)..variable : describeType($o)..accessor;
		}