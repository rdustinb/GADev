// An example of reading and processing a file
task readFile(
  input string thisFilename
);

  integer __fileLinecount = 0;

  // Create the filehandler for the file to read
  __fileHandler = $fopen(thisFilename, "r");

  // Loop through the file
  while($feof(__fileHandler)) begin

    // Process one line
    $fgets(__thisLine, __fileHandler);

    // Count the number of lines processed
    __fileLinecount++;

    // Do something if a character at a specific index in the line matches something else
    integer matchIndex = 0;
    if(__thisLine.getc(matchIndex) == "@") begin
    end

    // Grab a substring from the line
    __thisSubstring = __thisLine.substr(1, 16);
  end

endtask
