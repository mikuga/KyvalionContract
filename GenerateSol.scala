/**
  * Created by h.kawayoke on 2016/11/10.
  */

import scala.io.Source
import java.nio.file.Paths
import java.io.File
import java.io.{FileOutputStream, OutputStreamWriter}

def convSol(src: String,target: String) {
  val writer = new OutputStreamWriter(new FileOutputStream(target),"UTF-8")
  var isPragmaPrinted = false
  println(s"##$src")
  println("----------")
  val patternLineComment = "^//(.*)".r;
  val patternLineCommentAfter = "(.*)//(.*)".r;
  val patternPragma = "^pragma(.*)".r
  val patternImport = "^import \"(.*)\".*".r
  def load(path: String,writer: OutputStreamWriter) {
    val srcPath = Paths.get(path)
    val srcText = Source.fromFile(path)
    for (line <- srcText.getLines) {
      line match {
        case patternLineComment(k) =>
        case patternPragma(k) =>
          if(!isPragmaPrinted){
            isPragmaPrinted = true
            writer.write(s"$line\n")
          }
        case patternImport(k) => {
          val includePath = if (k.startsWith("/")) {
            k
          } else {
            Paths.get(s"${srcPath.getParent}/$k")
          }
          load(includePath.toString,writer)
        }
        case patternLineCommentAfter(k, v) => writer.write(s"${k.trim}\n")
        case s => writer.write(s"$s\n")
      }
    }
  }
  load(src,writer)
  writer.close
}
val outputDir = new File("output")
if(!outputDir.exists()) outputDir.mkdir()
convSol("./owner/OwnerValidatorImpl.sol","output/OwnerValidator.sol")
convSol("./off-chain/OffChainManagerImpl.sol","output/OffChainManager.sol")
convSol("./token/TokenContractImpl.sol","output/TokenContract.sol")
convSol("./MainContract.sol","output/MainContract.sol")
