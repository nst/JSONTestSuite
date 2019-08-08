package com.github.nst.dijon

import java.io.FileInputStream

import com.github.pathikrit.dijon._
import com.github.plokhotnyuk.jsoniter_scala.core._

object Main extends App {
  try {
    val in = new FileInputStream(args(0))
    try {
      readFromStream(in)
      System.exit(0)
    } catch {
      case ex: Throwable =>
        println(ex.getMessage)
        System.exit(1)
    } finally in.close()
  } catch {
    case ex: Throwable =>
      println(ex.getMessage)
      System.exit(2)
  }
}
