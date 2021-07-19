//
//  ViewController.swift
//  Clock
//
//  Created by Catalina on 11/19/19.
//  Copyright © 2019 Catalina. All rights reserved.
//

import UIKit
import AVFoundation
import Clocket

class ViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate{
    
    var audioRecorder: AVAudioRecorder!
    var audioSession = AVAudioSession.sharedInstance()
    var audioPlayer : AVAudioPlayer!
    var isPlaying = false
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var timeRateLabel: UILabel!
    @IBOutlet weak var displayRealTimeSwitch: UISwitch!
    @IBOutlet weak var countDownSwitch: UISwitch!
    @IBOutlet weak var manualTimeSetSwitch: UISwitch!
    @IBOutlet weak var timeRateStepper: UIStepper!
    @IBOutlet var controlPanels: [UIView]!
    
    @IBOutlet weak var clock: Clocket!
    
    @IBOutlet weak var recording: UIButton!
    @IBOutlet weak var play_recording: UIButton!
    @IBOutlet weak var txtInput: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            audioSession.requestRecordPermission() {
                [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.loadRecordingUI()
                    } else {
                        self.loadFailUI()
                    }
                }
            }
        } catch {
            self.loadFailUI()
        }
        clock.clockDelegate = self
        setupView()
        setupClock()
    }
    
    func loadRecordingUI() {
        print("loadRecordingUI: ")
        recording.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
    }
    
    func loadFailUI() {
        print("loadFailUI: ")
    }
    
    @objc func recordTapped() {
        if audioRecorder == nil {
            print("recordTapped: ")
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getFileUrl() -> URL
    {
        let filename = "recording.m4a"
        let filePath = getDocumentsDirectory().appendingPathComponent(filename)
        return filePath
    }
    
    func startRecording() {
        print("startRecording: ")
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        print(audioFilename as Any)
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()

            recording.setTitle("Tap to Stop", for: .normal)
        } catch {
            finishRecording(success: false)
        }
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil

        if success {
            recording.setTitle("Tap to Re-record", for: .normal)
        } else {
            recording.setTitle("Tap to Record", for: .normal)
            // recording failed :(
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    func prepare_play() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: getFileUrl())
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
        } catch {
            print("Error")
        }
    }
    
    func setupView() {
        controlPanels.forEach { (p: UIView) in
            p.layer.cornerRadius = p.bounds.height/2
            p.backgroundColor = UIColor(red: 160/255, green: 160/255, blue: 160/255, alpha: 1.0)
        }
    }
    
    func setupClock() {
        displayRealTimeSwitch.addTarget(self, action: #selector(realTimeSwitchStateChanged), for: UIControl.Event.valueChanged)
        displayRealTimeSwitch.setOn(false, animated: true)
        clock.displayRealTime = false
        countDownSwitch.addTarget(self, action: #selector(countDownSwitchStateChanged), for: UIControl.Event.valueChanged)
        countDownSwitch.setOn(false, animated: true)
        
        manualTimeSetSwitch.addTarget(self, action: #selector(manualTimeSetSwitchStateChanged), for: UIControl.Event.valueChanged)
        
        timeRateStepper.addTarget(self, action: #selector(timeRateStepperValueChanged), for: UIControl.Event.valueChanged)
        timeRateStepper.minimumValue = -10
        timeRateStepper.maximumValue = 10
        timeRateStepper.value = 1.0/clock.refreshInterval
        timeRateLabel.text = String(Int(timeRateStepper.value)) + "X"
        
        // delayed start for the real time clock
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(startRealTimeClock), userInfo: nil, repeats: false)
    }
    
    
    @objc func startRealTimeClock() {
        clock.displayRealTime = true
        displayRealTimeSwitch.setOn(true, animated: true)
        clock.refreshInterval = Double(1.0)
        startButton.setTitle("STOP", for: .normal)
        clock.startClock()
    }
    
    
    @IBAction func startButtonTapped(_ sender: Any) {
        print("startButtonTapped: ")
        
        clock.startClock()
        if clock.timer.isValid {
            startButton.setTitle("STOP", for: .normal)
        } else {
            startButton.setTitle("START", for: .normal)
        }
    }
    
    @IBAction func btnPlayRecordingAction(_ sender: Any) {
        if(isPlaying)
        {
            audioPlayer.stop()
            isPlaying = false
        }
        else
        {
            if FileManager.default.fileExists(atPath: getDocumentsDirectory().appendingPathComponent("recording.m4a").path)
            {
                prepare_play()
                audioPlayer.play()
                isPlaying = true
            }
            else
            { }
        }
    }
    
    
    @objc func realTimeSwitchStateChanged(switchState: UISwitch) {
        if switchState.isOn {
            clock.displayRealTime = true
            clock.reverseTime = false
            
            countDownSwitch.setOn(false, animated: true)
            clock.countDownTimer = false
            
            setTimeRate(timeRate: 1.0)
            if !clock.timer.isValid {
                clock.startClock()
            }
            startButton.setTitle("STOP", for: .normal)
        } else {
            clock.displayRealTime = false
        }
    }
    
    
    @objc func countDownSwitchStateChanged(switchState: UISwitch) {
        clock.stopClock()
        startButton.setTitle("START", for: .normal)
        
        if switchState.isOn {
            clock.countDownTimer = true
            
            clock.displayRealTime = false
            displayRealTimeSwitch.setOn(false, animated: true)
            
            manualTimeSetSwitch.setOn(true, animated: true)
            clock.manualTimeSetAllowed = true
            
            clock.setLocalTime(hour: 0, minute: 0, second: 5)
            clock.reverseTime = true
            setTimeRate(timeRate: -1.0)
        } else {
            clock.countDownTimer = false
        }
    }
    
    
    @objc func timeRateStepperValueChanged(_ sender: UIStepper) {
        displayRealTimeSwitch.setOn(false, animated: true)
        clock.displayRealTime = false
        
        if Int(sender.value) == 0 {
            if clock.countDownTimer {
                sender.value = -1
            } else {
                if clock.reverseTime {
                    sender.value = 1
                    clock.reverseTime = false
                } else {
                    sender.value = -1
                    clock.reverseTime = true
                }
            }
        }
        setTimeRate(timeRate: sender.value)
    }
    
    
    func setTimeRate(timeRate: Double) {
        clock.refreshInterval = Double(1.0/abs(timeRate))
        timeRateStepper.value = timeRate
        timeRateLabel.text = String(Int(timeRate)) + "X"
        if clock.timer.isValid {
            clock.stopClock()
            clock.startClock()
        }
    }
    
    
    @objc func manualTimeSetSwitchStateChanged(switchState: UISwitch) {
        clock.manualTimeSetAllowed = switchState.isOn
    }
}


extension ViewController: ClocketDelegate {
    
    func timeIsSetManually() {
        clock.displayRealTime = false
        displayRealTimeSwitch.setOn(false, animated: true)
    }
    
    
    func clockStopped() {
        startButton.setTitle("START", for: .normal)
    }
    
    
    func countDownExpired() {
        startButton.setTitle("START", for: .normal)
        clock.countDownTimer = false
        clock.reverseTime = false
        countDownSwitch.setOn(false, animated: true)
        setTimeRate(timeRate: 1.0)
        
        let localTimeComponents: Set<Calendar.Component> = [.hour, .minute, .second, .nanosecond]
        let currentTime = Calendar.current.dateComponents(localTimeComponents, from: Date())
        print("Countdown timer expired at", String(currentTime.hour!) + ":" +
            String(currentTime.minute!) + ":"
            + String(currentTime.second!) + ":" + String(currentTime.nanosecond!))
        
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
}

