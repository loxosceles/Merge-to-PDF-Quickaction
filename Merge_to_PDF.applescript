on run {inputFiles}
	-- Ensure files are selected
	if inputFiles is {} then
		display alert "No files selected" message "Please select files to merge."
		return
	end if
	
	-- Convert the first file alias to a POSIX path
	set firstFile to item 1 of inputFiles
	set firstFilePath to POSIX path of firstFile
	
	-- Get the folder path of the first file
	set folderPath to (do shell script "dirname " & quoted form of firstFilePath)
	
	-- Filter only supported file types (jpg, jpeg, png, pdf)
	set supportedExtensions to {"jpg", "jpeg", "png", "pdf"}
	set filteredFiles to {}
	repeat with inputFile in inputFiles
		set inputFilePath to POSIX path of inputFile
		set fileExtension to do shell script "echo " & quoted form of inputFilePath & " | awk -F. '{print tolower($NF)}'"
		if supportedExtensions contains fileExtension then
			set end of filteredFiles to inputFilePath
		end if
	end repeat
	
	-- Check if there are any supported files
	if filteredFiles is {} then
		display alert "No supported files" message "Selected files are not supported (jpg, jpeg, png, pdf)."
		return
	end if
	
	-- Create a temporary folder to store intermediate files
	set tempFolder to do shell script "mktemp -d"
	
	-- Convert images to PDFs (if needed) and prepare for merging
	set pdfFiles to {}
	repeat with i from 1 to count of filteredFiles
		set inputFile to item i of filteredFiles
		set fileExtension to do shell script "echo " & quoted form of inputFile & " | awk -F. '{print tolower($NF)}'"
		if fileExtension is in {"jpg", "jpeg", "png"} then
			-- Convert image to PDF
			set outputPDF to tempFolder & "/converted_" & i & ".pdf"
			do shell script "sips -s format pdf " & quoted form of inputFile & " --out " & quoted form of outputPDF
			set end of pdfFiles to outputPDF
		else if fileExtension is "pdf" then
			-- Add PDF directly
			set end of pdfFiles to inputFile
		end if
	end repeat
	
	-- Merge all PDFs into one
	set outputPDFPath to quoted form of (folderPath & "/MERGED.pdf")
	
	-- Build the list of PDF files for pdfunite
	set pdfFilesString to ""
	repeat with pdfFile in pdfFiles
		set pdfFilesString to pdfFilesString & " " & quoted form of pdfFile
	end repeat
	
	-- Use the full path to pdfunite
	set pdfunitePath to "/opt/homebrew/bin/pdfunite"
	do shell script pdfunitePath & pdfFilesString & " " & outputPDFPath
	
	-- Clean up temporary files
	do shell script "rm -rf " & quoted form of tempFolder
	
	return outputPDFPath
end run
