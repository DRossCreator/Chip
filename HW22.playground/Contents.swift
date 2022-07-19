import Foundation

 class Stack {
     var pop_id = 0
     var push_id = 0
     var stack = [Chip]()
     let syncQueue = DispatchQueue(label: "stack", qos: .utility, attributes: .concurrent)

     func push(item: Chip) {
         self.syncQueue.async(flags: .barrier) {
             self.push_id += 1
             self.stack.append(Chip.make())
             print("Создан \(self.push_id)й экземпляр.")
             print("Время создания: \(Date())")
             print(" ")
         }
     }

     func pop() -> Chip {
         var lastElement = Chip.make()
         self.syncQueue.async(flags: .barrier) { [self] in
             lastElement = self.stack.popLast() ?? Chip.make()
             self.pop_id += 1
             print("Удален \(pop_id)й экземпляр.")
             print("Время удаления: \(Date())")
             print(" ")
         }

         return lastElement
     }

 }

 var storage = Stack()

 class GenerationThread: Thread {
     private var timer = Timer()
     private var countTime = 0

     override func main() {
         self.timer = Timer(timeInterval: 2,
                                    target: self,
                                    selector: #selector(updateTimer),
                                    userInfo: nil,
                                    repeats: true)
         RunLoop.current.add(self.timer, forMode: .common)
         RunLoop.current.run()

         if Thread.current.isCancelled {
             return
         }
     }

     @objc func updateTimer() {
         storage.push(item: Chip.make())
         countTime += 1

         if countTime == 10 {
             timer.invalidate()
         }
     }
 }

 class WorkThread: Thread {
     override func main() {
         while !Thread.current.isCancelled {
             if storage.stack.last != nil {
                 let lastElemenet = storage.pop()
                 lastElemenet.sodering()
             }
         }
     }
 }

 let generationThread = GenerationThread()
 let workThread = WorkThread()

 generationThread.start()
print("запуск генерирующего потока")
print("время запуска: \(Date())")

 workThread.start()

 DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
     generationThread.cancel()
     print("поток остановлен")
     print("время остановки: \(Date())")
 }

 DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
     if generationThread.isCancelled && storage.stack.isEmpty {
         workThread.isCancelled
     }
 }
