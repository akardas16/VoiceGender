//
//  ContentView.swift
//  VoiceAnalyseGender
//
//  Created by Abdullah Kardas on 16.12.2022.
//

import SwiftUI
import Combine
import Charts

struct PitchModel:Identifiable {
    var id:UUID = UUID()
    var count:Int
    var pitch:Double
}

enum Gender {
case Male,Female,UnKnown
}

class ContentVM:ObservableObject,PitchEngineDelegate {
    
    lazy var pitchEngine: PitchEngine = { [weak self] in
        let config = Config(estimationStrategy: .barycentric)
      let pitchEngine = PitchEngine(config: config)
        
      pitchEngine.levelThreshold = -30.0
      return pitchEngine
    }()
 
    private var cancallable = Set<AnyCancellable>()
    
    private let pitchEngineSubject = PassthroughSubject<Double,Never>()
    
    
    
    @Published var points:[PitchModel] = [PitchModel(count: -1, pitch: 0)]
    
    @Published var arrayPitch:[Double] = [0]
    @Published var avarageValue:String = ""
    @Published var genderInfo:Gender = .UnKnown
    
    
    
    init(){
        
        pitchEngine.delegate = self
    
        pitchEngineSubject
            .filter{$0 >= 65.0 && $0 <= 300}
            .sink {[unowned self] value in
                self.arrayPitch.append(value)
                self.points.append(PitchModel(count: self.points.count, pitch: value))
            }.store(in: &cancallable)
        
        $arrayPitch.combineLatest($genderInfo)
            .map{
                var gender:Gender = .UnKnown
                let sum = $0.0.reduce(0,+)
                let avg = Double(sum)/Double($0.0.count)
                if avg >= 85 && avg <= 180 {
                    gender = .Male
                }else if avg >= 165 && avg <= 255 {
                    gender = .Female
                }else {
                    gender = .UnKnown
                }
                let a = String(format: "%.2f", avg)
                return (a,gender)
            }
        
            .sink(receiveValue: {[unowned self] value in
                self.avarageValue = value.0
                self.genderInfo = value.1
                
            }).store(in: &cancallable)
            

    }
    

    
    func pitchEngine(_ pitchEngine: PitchEngine, didReceivePitch pitch: Pitch) {
        pitchEngineSubject.send(pitch.frequency)
    }

    func pitchEngine(_ pitchEngine: PitchEngine, didReceiveError error: Error) {
       // pitchEngineSubject.send(completion: .failure(error))
     // print(error)
    }

    public func pitchEngineWentBelowLevelThreshold(_ pitchEngine: PitchEngine) {
     // print("Below level threshold")
    }
    
}

struct ContentView: View {
    
    @ObservedObject var vm = ContentVM()
    var body: some View {
        VStack {
            Spacer()
            if vm.genderInfo == .Male {
                Text("Male").font(.title.bold()).foregroundColor(.blue)
            }else if vm.genderInfo == .Female {
                Text("Female").font(.title.bold()).foregroundColor(.purple)
            }else {
                Text("").font(.title.bold())
            }
            Spacer()
            Text(vm.avarageValue).font(.title.bold()).foregroundColor(.cyan)
            Spacer()
            Chart(vm.points) {
                LineMark(x: .value("Count", $0.count),
                         y: .value("pitch", $0.pitch))
            }.chartYScale(domain: 0...300).frame(height: 250)
         
            Spacer()
        
            Button {
                vm.arrayPitch.removeAll()
                vm.avarageValue = ""
                vm.genderInfo = .UnKnown
                vm.points.removeAll()
                vm.pitchEngine.start()
           
            } label: {
                Text("Start Pitch Engine").foregroundColor(.white).font(.callout.bold()).padding().frame(maxWidth: .infinity).background {
                    Capsule(style: .continuous).fill(.green)
                }
            }.padding(.horizontal,32)
            
           
            
            Button {
                vm.pitchEngine.stop()
//                vm.pitchEngine.active ? vm.pitchEngine.stop() : vm.pitchEngine.start()
           
            } label: {
                Text("Stop Pitch Engine").foregroundColor(.white).font(.callout.bold()).padding().frame(maxWidth: .infinity).background {
                    Capsule(style: .continuous).fill(.red)
                }
            }.padding(.horizontal,32)
            
            
        

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


