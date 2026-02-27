# Pre-compilation hook to generate mermaid diagrams.
# This script runs before LaTeX compilation. It finds all .mmd files
# in `assets/mermaid/` and compiles them to .png in `assets/diagrams/`
# if they have been modified or if the .png does not exist.

# Source: assets/mermaid/*.mmd
# Destination: assets/diagrams/*.png

# Ensure the output directory exists.
if (!-d "assets/diagrams") {
    mkdir "assets/diagrams" or die "Could not create directory assets/diagrams: $!";
}

# Find all .mmd files.
my @mmd_files = glob "assets/mermaid/*.mmd";

# Loop through each file and compile if it's new or has been modified.
foreach my $mmd_file (@mmd_files) {
    # Extract the base name of the file (e.g., 'diagrama1').
    # We use a regex that handles both / and \ for Windows compatibility.
    my $base_name = $mmd_file;
    $base_name =~ s/^.*[\\\/]//;
    $base_name =~ s/\.mmd$//;

    my $png_file = "assets/diagrams/$base_name.png";

    # If the .png doesn't exist or is older than the .mmd, regenerate it.
    if ( !-e $png_file or (stat($mmd_file))[9] > (stat($png_file))[9] ) {
        print "Latexmk: Regenerating '$png_file' from '$mmd_file'\n";
        system("mmdc.cmd -i \"$mmd_file\" -o \"$png_file\" -w 1200");
    }
}