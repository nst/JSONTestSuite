import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonConfiguration
import java.io.File
import java.io.IOException
import kotlin.system.exitProcess

fun main(args: Array<String>) {

    if (args.isEmpty()) {
        println("Usage: java TestJSONParsing file.json")
        exitProcess(2)
    }

    try {
        val s = File(args[0]).readText()
        println(args[0])

        if (isValidJSON(s)) {
            println("valid")
            exitProcess(0)
        }
        println("invalid")
        exitProcess(1)
    } catch (e: IOException) {
        println("not found")
        exitProcess(2)
    } catch (e: Throwable) {
        println("Other error")
        println(e.toString())
        exitProcess(2)
    }

}

fun isValidJSON(s: String): Boolean {
    return try {
        when {
            s.isNeitherArrayNotObject() -> {
                println("Not an array or object")
                false
            }
            s.isObject() -> {
                val mapper = Json(JsonConfiguration.Stable)
                val obj = mapper.parseJson(s)
                println(obj)
                println(obj::class.simpleName)
                true
            }
            else -> {
                val mapper = Json(JsonConfiguration.Stable)
                val array = mapper.parseJson(s)
                println(array)
                println(array::class.simpleName)
                true
            }
        }
    } catch (e: SerializationException) {
        println(e)
        false
    }
}

fun String.isObject() = indexOf('{') >= 0 && (indexOf('[') < 0 || indexOf('{') < indexOf('['))
fun String.isNeitherArrayNotObject() = indexOf('{') < 0 && indexOf('[') < 0
