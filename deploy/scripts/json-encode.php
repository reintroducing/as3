<?php
	$object = json_decode($_POST['flashData']);
	
	echo json_encode($object);
?>