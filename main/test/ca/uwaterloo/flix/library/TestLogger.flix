use Assert.{assertEq}

mod TestLogger {
    @Test
    def testRunWithList01(): Unit \ Assert =
        let (_, list) = run {
            Logger.fatal("A fatal error has occured")
        } with Logger.runWithList;
        let expected = List#{(Severity.Fatal, RichString.fromString("A fatal error has occured"))};
        assertEq(expected = expected, list)

    @Test
    def testRunWithList02(): Unit \ Assert =
        let (_, list) = run {
            Logger.fatal("A fatal error has occured");
            Logger.info("An info line")
        } with Logger.runWithList;
        let expected = List#{
            (Severity.Fatal, RichString.fromString("A fatal error has occured")),
            (Severity.Info, RichString.fromString("An info line"))
        };
        assertEq(expected = expected, list)

    @Test
    def testRunWithList03(): Unit \ Assert =
        let (stdRes, _list) = run {
            Logger.fatal("A fatal error has occured");
            5 // to show that we have more code executing "normally"
        } with Logger.runWithList;
        assertEq(expected = 5, stdRes)
}