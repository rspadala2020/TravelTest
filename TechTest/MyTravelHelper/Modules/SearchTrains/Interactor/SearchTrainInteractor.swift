//
//  SearchTrainInteractor.swift
//  MyTravelHelper
//
//  Created by Satish on 11/03/19.
//  Copyright © 2019 Sample. All rights reserved.
//

import Foundation
import XMLCoder

class SearchTrainInteractor: PresenterToInteractorProtocol {
    var _sourceStationCode = String()
    var _destinationStationCode = String()
    var presenter: InteractorToPresenterProtocol?
    var networkManager: NetworkManager = NetworkManager()
    let session = URLSession.shared
    
    func fetchallStations() {
        networkManager.makeServiceCallForRequest(urlString: "http://api.irishrail.ie/realtime/realtime.asmx/getAllStationsXML", presenter: self.presenter) { (data, error) in
            if error == nil, let responseData = data {
                let station = try? XMLDecoder().decode(Stations.self, from: responseData)
                self.presenter!.stationListFetched(list: station!.stationsList)
            }
        }
    }
    
    func fetchTrainsFromSource(sourceCode: String, destinationCode: String) {
        _sourceStationCode = sourceCode
        _destinationStationCode = destinationCode
        networkManager.makeServiceCallForRequest(urlString: "http://api.irishrail.ie/realtime/realtime.asmx/getStationDataByCodeXML?StationCode=\(sourceCode)", presenter: self.presenter) { (data, error) in
            if error == nil, let responseData = data {
                let decoder = XMLDecoder()
                decoder.shouldProcessNamespaces = true
                let stationData = try? decoder.decode(StationData.self, from: responseData)
                if let _trainsList = stationData?.trainsList, _trainsList.isEmpty == false {
                    self.proceesTrainListforDestinationCheck(trainsList: _trainsList)
                } else {
                    DispatchQueue.main.async {
                        self.presenter!.showNoTrainAvailbilityFromSource()
                    }
                }
            }
        }
        
    }
    
    private func proceesTrainListforDestinationCheck(trainsList: [StationTrain]) {
        var _trainsList = trainsList
        let today = Date()
        let group = DispatchGroup()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let dateString = formatter.string(from: today)
        
        for index  in 0...trainsList.count-1 {
            group.enter()
            let _urlString = "http://api.irishrail.ie/realtime/realtime.asmx/getTrainMovementsXML?TrainId=\(trainsList[index].trainCode)&TrainDate=\(dateString)"
            
            networkManager.makeServiceCallForRequest(urlString: _urlString, presenter: self.presenter) { (data, error) in
                if error == nil, let responseData = data {
                    let decoder = XMLDecoder()
                    decoder.shouldProcessNamespaces = true
                    let trainMovements = try? decoder.decode(TrainMovementsData.self, from: responseData)
                    
                    if let _movements = trainMovements?.trainMovements {
                        let sourceIndex = _movements.firstIndex(where: {$0.locationCode.caseInsensitiveCompare(self._sourceStationCode) == .orderedSame})
                        let destinationIndex = _movements.firstIndex(where: {$0.locationCode.caseInsensitiveCompare(self._destinationStationCode) == .orderedSame})
                        let desiredStationMoment = _movements.filter{$0.locationCode.caseInsensitiveCompare(self._destinationStationCode) == .orderedSame}
                        let isDestinationAvailable = desiredStationMoment.count == 1
                        
                        if isDestinationAvailable  && sourceIndex! < destinationIndex! {
                            _trainsList[index].destinationDetails = desiredStationMoment.first
                        }
                    }
                }
                group.leave()
            }
            
        }
        
        group.notify(queue: DispatchQueue.main) {
            let sourceToDestinationTrains = _trainsList.filter{$0.destinationDetails != nil}
            self.presenter!.fetchedTrainsList(trainsList: sourceToDestinationTrains)
        }
    }
}
