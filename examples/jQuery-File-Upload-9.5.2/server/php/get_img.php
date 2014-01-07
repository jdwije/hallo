<?php 

# the dir to read files from	
$file_dir = 'files';

# filter that file directory exists
if ( is_dir( $file_dir ) ) {
	# found. loop and echo files.
	$dir = opendir($file_dir);
	$response = array();

	while ( $file = readdir( $dir) ) {
		$info = pathinfo($file);
		$basename = $info['basename'];
		@$ext = $info['extension'];

		# filter hidden and sys files
		if ( $basename != '.' AND $basename != '..' ) {
			# only read images
			if ( $ext == 'jpg' ) {
				$furl = 'http://localhost:8888/hallo/examples/jQuery-File-Upload-9.5.2/server/php/files/' . urlencode( $file );
				array_push($response, $furl);
			}
		}
	}

	echo json_encode($response);

}	
else {
	die ( "could not find file directory ");
}

?>