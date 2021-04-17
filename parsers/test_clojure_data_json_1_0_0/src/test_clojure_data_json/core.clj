(ns test-clojure-data-json.core
  (:require [clojure.data.json :as json])
  (:import [java.nio.file Files Paths])
  (:gen-class))

(defn -main
  "I don't do a whole lot ... yet."
  [& args]
  (when (zero? (count args))
    (println "Usage more args")
    (System/exit 2))
  (try
    (let [s (slurp (first args))]
      (try
        (json/read-str s)
         (println "Valid:" (first args))
         (System/exit 0)
        (catch Exception _
          (println "Invalid:" (first args))
          (System/exit 1))))
    (catch Exception _
      (println "not found" _)
      (System/exit 2))))
