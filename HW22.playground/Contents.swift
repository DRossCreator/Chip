import Foundation

 class Stack {
     var stack = [Chip]()
     let syncQueue = DispatchQueue(label: "stack", qos: .utility, attributes: .concurrent)

     func pop() -> Chip {
         var lastElement = Chip.make()
         self.syncQueue.async(flags: .barrier) {
             lastElement = self.stack.popLast() ?? Chip.make()
         }

         return lastElement
     }

     func push(item: Chip) {
         self.syncQueue.async(flags: .barrier) {
             self.stack.append(Chip.make())
         }
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
 workThread.start()

 DispatchQueue.main.asyncAfter(deadline: .now() + 25) {
     generationThread.cancel()
 }

 DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
     if generationThread.isCancelled && storage.stack.isEmpty {
         workThread.isCancelled
     }
 }
