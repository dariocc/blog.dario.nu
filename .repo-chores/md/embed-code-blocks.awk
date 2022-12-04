BEGIN{
    if ("" == BASEDIR) {
        BASEDIR = "."
    }
    file= ""

    WAITING_CODEBLOCK="waiting-code"
    BEGIN_CODEBLOCK="begin-code"
    END_CODEBLOCK="end_Code"
    
    state= WAITING_CODEBLOCK
}
/^```!/ {
    file = $0
    sub(/.*!/,"", file)
    state = BEGIN_CODEBLOCK
}
/^```$/ {
    if (BEGIN_CODEBLOCK == state) {
        state = END_CODEBLOCK
    }
}
{
    if (BEGIN_CODEBLOCK == state) {
        next
    }
    else if (END_CODEBLOCK == state) {
        print "```!" file
        file_path=BASEDIR"/"file
        while ((getline line < file_path) > 0) {
            print line
        }
        close(file_path)
        print "```"

        state = WAITING_CODEBLOCK
        file = ""
    }
    else {
        print
    }
}