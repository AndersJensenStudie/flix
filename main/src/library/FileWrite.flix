/*
 *  Copyright 2024 Magnus Madsen
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

///
/// An effect used to write to the file system.
///
/// All operations on this effect are infallible.
/// If an operation fails the handler must deal with it.
///
pub eff FileWrite {

    ///
    /// Writes `str` to the given file `f`.
    ///
    /// Creates file `f` if it does not exist. Overwrites it if it exists.
    ///
    def write(data: {str = String}, f: String): Unit

    ///
    /// Writes `lines` to the given file `f`.
    ///
    /// Creates `f` if it does not exist. Overwrites it if it exists.
    ///
    def writeLines(data: {lines = List[String]}, f: String): Unit

    ///
    /// Writes `data` to the given file `f`.
    ///
    /// Creates file `f` if it does not exist. Overwrites it if it exists.
    ///
    def writeBytes(data: Vector[Int8], f: String): Unit

    ///
    /// Appends `str` to the given file `f`.
    ///
    /// Creates the file `f` if it does not exist.
    ///
    def append(data: {str = String}, f: String): Unit

    ///
    /// Appends `lines` to the given file `f`.
    ///
    /// Creates the file `f` if it does not exist.
    ///
    def appendLines(data: {lines = List[String]}, f: String): Unit

    ///
    /// Appends `data` to the given file `f`.
    ///
    /// Creates the file `f` if it does not exist.
    ///
    def appendBytes(data: Vector[Int8], f: String): Unit

    ///
    /// Truncates the given file `f`.
    ///
    def truncate(f: String): Unit

    ///
    /// Creates the directory `d`.
    ///
    def mkDir(d: String): Unit

    ///
    /// Creates the directory `d` and all its parent directories.
    ///
    def mkDirs(d: String): Unit

    ///
    /// Creates a new temporary directory with the given prefix.
    ///
    /// Returns the path to the directory.
    ///
    def mkTempDir(prefix: String): String

}

pub mod FileWrite {

    import java.io.IOException
    import java.lang.IllegalArgumentException
    import java.lang.UnsupportedOperationException
    import java.nio.charset.StandardCharsets
    import java.nio.file.attribute.FileAttribute
    import java.nio.file.FileAlreadyExistsException
    import java.nio.file.Files
    import java.nio.file.InvalidPathException
    import java.nio.file.OpenOption
    import java.nio.file.Paths
    import java.nio.file.StandardOpenOption

    use IoError.IoError
    use IoError.ErrorKind

    ///
    /// Handles the `FileWrite` effect of the given function `f`.
    ///
    /// In other words, re-interprets the `FileWrite` effect using the `IO` effect.
    ///
    pub def handle(f: a -> b \ ef): a -> Result[IoError, b] \ (ef - FileWrite) + IO = x ->
        run {
            Ok(f(x))
        } with handler FileWrite {
            def write(data, file, k) = {
                try {
                    let bytes = data#str.getBytes(StandardCharsets.UTF_8);
                    Files.write(Paths.get(file), bytes, (...{}: Vector[OpenOption]));
                    k(())
                } catch {
                    case ex: InvalidPathException          => Err(IoError(ErrorKind.InvalidPath, ex.getMessage()))
                    case ex: UnsupportedOperationException => Err(IoError(ErrorKind.Unsupported, ex.getMessage()))
                    case ex: IOException                   => Err(IoError(ErrorKind.Other, ex.getMessage()))
                }
            }

            def writeLines(data, file, k) = {
                try {
                    let bf = Files.newBufferedWriter(Paths.get(file), (...{}: Vector[OpenOption]));
                    List.forEach(line -> {
                        bf.write(line, 0, String.length(line));
                        bf.newLine()
                    }, data#lines);
                    bf.close();
                    k(())
                } catch {
                    case ex: InvalidPathException          => Err(IoError(ErrorKind.InvalidPath, ex.getMessage()))
                    case ex: UnsupportedOperationException => Err(IoError(ErrorKind.Unsupported, ex.getMessage()))
                    case ex: IOException                   => Err(IoError(ErrorKind.Other, ex.getMessage()))
                }
            }

            def writeBytes(data, file, k) = {
                try {
                    region rc {
                        let bytes = Vector.toArray(rc, data);
                        Files.write(Paths.get(file), bytes, (...{}: Vector[OpenOption]));
                        k(())
                    }
                } catch {
                    case ex: InvalidPathException          => Err(IoError(ErrorKind.InvalidPath, ex.getMessage()))
                    case ex: UnsupportedOperationException => Err(IoError(ErrorKind.Unsupported, ex.getMessage()))
                    case ex: IOException                   => Err(IoError(ErrorKind.Other, ex.getMessage()))
                }
            }

            def append(data, file, k) = {
                try {
                    let bytes = data#str.getBytes(StandardCharsets.UTF_8);
                    let opts: Vector[OpenOption] = ...{
                        checked_cast(StandardOpenOption.APPEND), 
                        checked_cast(StandardOpenOption.CREATE)
                    };
                    Files.write(Paths.get(file), bytes, opts);
                    k(())
                } catch {
                    case ex: InvalidPathException          => Err(IoError(ErrorKind.InvalidPath, ex.getMessage()))
                    case ex: UnsupportedOperationException => Err(IoError(ErrorKind.Unsupported, ex.getMessage()))
                    case ex: IOException                   => Err(IoError(ErrorKind.Other, ex.getMessage()))
                }
            }

            def appendLines(data, file, k) = {
                try {
                    let opts: Vector[OpenOption] = ...{
                        checked_cast(StandardOpenOption.APPEND), 
                        checked_cast(StandardOpenOption.CREATE)
                    };
                    let bf = Files.newBufferedWriter(Paths.get(file), opts);
                    List.forEach(line -> {
                        bf.write(line, 0, String.length(line));
                        bf.newLine()
                    }, data#lines);
                    bf.close();
                    k(())
                } catch {
                    case ex: InvalidPathException          => Err(IoError(ErrorKind.InvalidPath, ex.getMessage()))
                    case ex: UnsupportedOperationException => Err(IoError(ErrorKind.Unsupported, ex.getMessage()))
                    case ex: IOException                   => Err(IoError(ErrorKind.Other, ex.getMessage()))
                }
            }

            def appendBytes(data, file, k) = {
                try {
                    region rc {
                        let bytes = Vector.toArray(rc, data);
                        let opts: Vector[OpenOption] = ...{
                            checked_cast(StandardOpenOption.APPEND), 
                            checked_cast(StandardOpenOption.CREATE)
                        };
                        Files.write(Paths.get(file), bytes, opts);
                        k(())
                    }
                } catch {
                    case ex: InvalidPathException          => Err(IoError(ErrorKind.InvalidPath, ex.getMessage()))
                    case ex: UnsupportedOperationException => Err(IoError(ErrorKind.Unsupported, ex.getMessage()))
                    case ex: IOException                   => Err(IoError(ErrorKind.Other, ex.getMessage()))
                }
            }

            def truncate(file, k) = {
                try {
                    region rc {
                        let opt: OpenOption = checked_cast(StandardOpenOption.TRUNCATE_EXISTING);
                        let arr: Array[Int8, rc] = Array#{} @ rc;
                        Files.write(Paths.get(file), arr, ...{opt});
                        k(())
                    }
                } catch {
                    case ex: InvalidPathException          => Err(IoError(ErrorKind.InvalidPath, ex.getMessage()))
                    case ex: UnsupportedOperationException => Err(IoError(ErrorKind.Unsupported, ex.getMessage()))
                    case ex: IOException                   => Err(IoError(ErrorKind.Other, ex.getMessage()))
                }
            }

            def mkDir(d, k) = {
                try {
                    Files.createDirectory(Paths.get(d), (...{}: Vector[FileAttribute]));
                    k(())
                } catch {
                    case ex: InvalidPathException          => Err(IoError(ErrorKind.InvalidPath, ex.getMessage()))
                    case ex: UnsupportedOperationException => Err(IoError(ErrorKind.Unsupported, ex.getMessage()))
                    case ex: FileAlreadyExistsException    => Err(IoError(ErrorKind.AlreadyExists, ex.getMessage()))
                    case ex: IOException                   => Err(IoError(ErrorKind.Other, ex.getMessage()))
                }
            }

            def mkDirs(d, k) = {
                try {
                    Files.createDirectories(Paths.get(d), (...{}: Vector[FileAttribute]));
                    k(())
                } catch {
                    case ex: InvalidPathException          => Err(IoError(ErrorKind.InvalidPath, ex.getMessage()))
                    case ex: UnsupportedOperationException => Err(IoError(ErrorKind.Unsupported, ex.getMessage()))
                    case ex: FileAlreadyExistsException    => Err(IoError(ErrorKind.AlreadyExists, ex.getMessage()))
                    case ex: IOException                   => Err(IoError(ErrorKind.Other, ex.getMessage()))
                }
            }

            def mkTempDir(prefix, k) = {
                try {
                    let path = Files.createTempDirectory(prefix, (...{}: Vector[FileAttribute]));
                    k(path.toString())
                } catch {
                    case ex: IllegalArgumentException      => Err(IoError(ErrorKind.InvalidPath, ex.getMessage()))
                    case ex: UnsupportedOperationException => Err(IoError(ErrorKind.Unsupported, ex.getMessage()))
                    case ex: IOException                   => Err(IoError(ErrorKind.Other, ex.getMessage()))
                }
            }
        }

    ///
    /// Runs the `FileWrite` effect of the given function `f`.
    ///
    /// In other words, re-interprets the `FileWrite` effect using the `IO` effect.
    ///
    pub def runWithIO(f: Unit -> a \ ef): Result[IoError, a] \ (ef - FileWrite) + {IO} = handle(f)()

    ///
    /// Handles the `FileWrite` effect of the given function `f` with the `FileWriteWithResult` effect.
    ///
    /// In other words, re-interprets the `FileWrite` effect using the `FileWriteWithResult` effect.
    ///
    pub def handleWithFileWriteWithResult(f: a -> b \ ef): a -> Result[IoError, b] \ (ef - FileWrite) + FileWriteWithResult = 
        x -> run {
            Ok(f(x))
        } with handler FileWrite {
            def write(data, fi, k) = 
                runAndUnfold(FileWriteWithResult.write(data), fi, k)
            def writeLines(data, fi, k) = 
                runAndUnfold(FileWriteWithResult.writeLines(data), fi, k)
            def writeBytes(data, fi, k) = 
                runAndUnfold(FileWriteWithResult.writeBytes(data), fi, k)
            def append(data, fi, k) = 
                runAndUnfold(FileWriteWithResult.append(data), fi, k)
            def appendLines(data, fi, k) = 
                runAndUnfold(FileWriteWithResult.appendLines(data), fi, k)
            def appendBytes(data, fi, k) = 
                runAndUnfold(FileWriteWithResult.appendBytes(data), fi, k)
            def truncate(fi, k) = 
                runAndUnfold(FileWriteWithResult.truncate, fi, k)
            def mkDir(d, k) = 
                runAndUnfold(FileWriteWithResult.mkDir, d, k)
            def mkDirs(d, k) = 
                runAndUnfold(FileWriteWithResult.mkDirs, d, k)
            def mkTempDir(prefix, k) = 
                let res = FileWriteWithResult.mkTempDir(prefix);
                match res {
                    case Ok(ok) => k(ok)
                    case Err(t) => Err(t)
                }
        }

    def runAndUnfold(f: a -> Result[IoError, Unit] \ ef, param: a, k: Unit -> Result[IoError, b] \ ef2): Result[IoError, b] \ ef + ef2 = 
        let res = f(param);
        match res {
            case Ok(ok) => k(ok) 
            case Err(t) => Err(t)
        }

    ///
    /// Handles the `FileWrite` effect of the given function `f` with the `FileWriteWithResult` effect.
    ///
    /// In other words, re-interprets the `FileWrite` effect using the `FileWriteWithResult` effect.
    ///
    pub def runWithFileWriteWithResult(f: Unit -> b \ ef): Result[IoError, b] \ (ef - FileWrite) + FileWriteWithResult = 
        handleWithFileWriteWithResult(f)()

}