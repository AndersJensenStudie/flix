mod TestLogger {
    use Assert.{assertEq}

    @Test
    def testRunWithList01(): Unit \ Assert =
        let (_, list) = run {
            Logger.fatal("A fatal error has occured")
        } with Logger.runWithList;
        let expected = List#{(Severity.Fatal, "A fatal error has occured")};
        assertEq(expected = expected, turnToString(list))



    @Test
    def testRunWithList02(): Unit \ Assert =
        let (_, list) = run {
            Logger.fatal("A fatal error has occured");
            Logger.info("An info line")
        } with Logger.runWithList;
        let expected = List#{
            (Severity.Fatal, "A fatal error has occured"),
            (Severity.Info, "An info line")
        };
        assertEq(expected = expected, turnToString(list))

    // to show that we can have more code executing "normally", that is also returned.
    @Test
    def testRunWithList03(): Unit \ Assert =
        let (stdRes, _list) = run {
            Logger.fatal("A fatal error has occured");
            5 
        } with Logger.runWithList;
        assertEq(expected = 5, stdRes)
    
    def turnToString(l: List[(Severity, RichString)]): List[(Severity, String)] = 
        List.map(x -> {let (sev, rs) = x; (sev, RichString.toString(rs))}, l)
}

