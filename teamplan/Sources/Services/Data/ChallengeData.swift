//
//  ChallengeData.swift
//  투두팡
//
//  Created by Crossbell on 8/24/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class ChallengeList {
    
    func getData() -> [ChallengeInfoDTO] {
        return serviceTermList + totalTodoList + projectAlertList + projectFinishList + waterDropList
    }
    
    func getServiceTermSize() -> Int {
        return serviceTermList.count
    }
    
    func getTotalTodoListSize() -> Int {
        return totalTodoList.count
    }
    
    func getProjectAlertListSize() -> Int {
        return projectAlertList.count
    }
    
    func getProjectFinishListSize() -> Int {
        return projectFinishList.count
    }
    
    func getWaterDropListSize() -> Int {
        return waterDropList.count
    }
    
    private let serviceTermList: [ChallengeInfoDTO] = [
        ChallengeInfoDTO(challengeId: 100, title: "첫걸음 지킴이", desc: "최초 투두팡 사용", goal: 1, type: .serviceTerm, reward: 5, step: 1, version: 1),
        ChallengeInfoDTO(challengeId: 101, title: "꾸준함 지킴이", desc: "투두팡 사용 7일", goal: 7, type: .serviceTerm, reward: 5, step: 2, version: 1),
        ChallengeInfoDTO(challengeId: 102, title: "익숙한 지킴이", desc: "투두팡 사용 30일", goal: 30, type: .serviceTerm, reward: 5, step: 3, version: 1),
        ChallengeInfoDTO(challengeId: 103, title: "노력파 지킴이", desc: "투두팡 사용 60일", goal: 60, type: .serviceTerm, reward: 5, step: 4, version: 1),
        ChallengeInfoDTO(challengeId: 104, title: "달관 지킴이", desc: "투두팡 사용 150일", goal: 150, type: .serviceTerm, reward: 5, step: 5, version: 1),
        ChallengeInfoDTO(challengeId: 105, title: "개근 지킴이", desc: "투두팡 사용 240일", goal: 240, type: .serviceTerm, reward: 5, step: 6, version: 1),
        ChallengeInfoDTO(challengeId: 106, title: "투두팡 지킴이", desc: "투두팡 사용 330일", goal: 330, type: .serviceTerm, reward: 5, step: 7, version: 1)
    ]
    
    private let totalTodoList: [ChallengeInfoDTO] = [
        ChallengeInfoDTO(challengeId: 200, title: "신기한 지킴이", desc: "최초 할 일 등록", goal: 1, type: .totalTodo, reward: 5, step: 1, version: 1),
        ChallengeInfoDTO(challengeId: 201, title: "흥미로운 지킴이", desc: "할 일 등록 20개", goal: 20, type: .totalTodo, reward: 5, step: 2, version: 1),
        ChallengeInfoDTO(challengeId: 202, title: "감잡은 지킴이", desc: "할 일 등록 60개", goal: 60, type: .totalTodo, reward: 5, step: 3, version: 1),
        ChallengeInfoDTO(challengeId: 203, title: "적응한 지킴이", desc: "할 일 등록 140개", goal: 140, type: .totalTodo, reward: 5, step: 4, version: 1),
        ChallengeInfoDTO(challengeId: 204, title: "본격적인 지킴이", desc: "할 일 등록 300개", goal: 300, type: .totalTodo, reward: 5, step: 5, version: 1),
        ChallengeInfoDTO(challengeId: 205, title: "숙련된 지킴이", desc: "할 일 등록 500개", goal: 500, type: .totalTodo, reward: 5, step: 6, version: 1),
        ChallengeInfoDTO(challengeId: 206, title: "투.잘.알 지킴이", desc: "할 일 등록 1000개", goal: 1000, type: .totalTodo, reward: 5, step: 7, version: 1)
    ]
    
    private let projectAlertList: [ChallengeInfoDTO] = [
        ChallengeInfoDTO(challengeId: 300, title: "실수한 지킴이", desc: "최초 기한초과", goal: 1, type: .projectAlert, reward: 10, step: 1, version: 1),
        ChallengeInfoDTO(challengeId: 301, title: "바빴던 지킴이", desc: "목표 5개 기한초과", goal: 5, type: .projectAlert, reward: 10, step: 2, version: 1),
        ChallengeInfoDTO(challengeId: 302, title: "작심삼일 지킴이", desc: "목표 15개 기한초과", goal: 15, type: .projectAlert, reward: 10, step: 3, version: 1),
        ChallengeInfoDTO(challengeId: 303, title: "의도적인 지킴이", desc: "목표 30개 기한초과", goal: 30, type: .projectAlert, reward: 10, step: 4, version: 1),
        ChallengeInfoDTO(challengeId: 304, title: "즐기는 지킴이", desc: "목표 60개 기한초과", goal: 60, type: .projectAlert, reward: 10, step: 5, version: 1),
        ChallengeInfoDTO(challengeId: 305, title: "배반한 지킴이", desc: "목표 90개 기한초과", goal: 90, type: .projectAlert, reward: 10, step: 6, version: 1),
        ChallengeInfoDTO(challengeId: 306, title: "적대하는 지킴이", desc: "목표 150개 기한초과", goal: 150, type: .projectAlert, reward: 10, step: 7, version: 1)
    ]
    
    private let projectFinishList: [ChallengeInfoDTO] = [
        ChallengeInfoDTO(challengeId: 400, title: "새내기 지킴이", desc: "최초 목표해결", goal: 1, type: .projectFinish, reward: 10, step: 1, version: 1),
        ChallengeInfoDTO(challengeId: 401, title: "약속한 지킴이", desc: "목표 5개 해결", goal: 5, type: .projectFinish, reward: 10, step: 2, version: 1),
        ChallengeInfoDTO(challengeId: 402, title: "꼼꼼한 지킴이", desc: "목표 15개 해결", goal: 15, type: .projectFinish, reward: 10, step: 3, version: 1),
        ChallengeInfoDTO(challengeId: 403, title: "성실한 지킴이", desc: "목표 30개 해결", goal: 30, type: .projectFinish, reward: 10, step: 4, version: 1),
        ChallengeInfoDTO(challengeId: 404, title: "계획적인 지킴이", desc: "목표 60개 해결", goal: 60, type: .projectFinish, reward: 10, step: 5, version: 1),
        ChallengeInfoDTO(challengeId: 405, title: "갓생 지킴이", desc: "목표 90개 해결", goal: 90, type: .projectFinish, reward: 10, step: 6, version: 1),
        ChallengeInfoDTO(challengeId: 406, title: "파워J 지킴이", desc: "목표 150개 해결", goal: 150, type: .projectFinish, reward: 10, step: 7, version: 1)
    ]
    
    private let waterDropList: [ChallengeInfoDTO] = [
        ChallengeInfoDTO(challengeId: 500, title: "이슬", desc: "최초 물방울 보유", goal: 1, type: .waterDrop, reward: 10, step: 1, version: 1),
        ChallengeInfoDTO(challengeId: 501, title: "접시물", desc: "물방울 5개 보유", goal: 5, type: .waterDrop, reward: 10, step: 2, version: 1),
        ChallengeInfoDTO(challengeId: 502, title: "텀블러", desc: "물방울 10개 보유", goal: 10, type: .waterDrop, reward: 10, step: 3, version: 1),
        ChallengeInfoDTO(challengeId: 503, title: "정수기", desc: "물방울 30개 보유", goal: 30, type: .waterDrop, reward: 10, step: 4, version: 1),
        ChallengeInfoDTO(challengeId: 504, title: "항아리", desc: "물방울 50개 보유", goal: 50, type: .waterDrop, reward: 10, step: 5, version: 1),
        ChallengeInfoDTO(challengeId: 505, title: "웅덩이", desc: "물방울 70개 보유", goal: 70, type: .waterDrop, reward: 10, step: 6, version: 1),
        ChallengeInfoDTO(challengeId: 506, title: "물탱크", desc: "물방울 90개 보유", goal: 90, type: .waterDrop, reward: 10, step: 7, version: 1),
        ChallengeInfoDTO(challengeId: 507, title: "저수지", desc: "물방울 150개 보유", goal: 150, type: .waterDrop, reward: 10, step: 8, version: 1),
        ChallengeInfoDTO(challengeId: 508, title: "팔당댐", desc: "물방울 200개 보유", goal: 200, type: .waterDrop, reward: 10, step: 9, version: 1),
        ChallengeInfoDTO(challengeId: 509, title: "한강", desc: "물방울 250개 보유", goal: 250, type: .waterDrop, reward: 10, step: 10, version: 1),
        ChallengeInfoDTO(challengeId: 510, title: "앞바다", desc: "물방울 300개 보유", goal: 300, type: .waterDrop, reward: 10, step: 11, version: 1)
    ]
}

struct ChallengeInfoDTO {
    let challengeId: Int
    let title: String
    let desc: String
    let goal: Int
    let type: ChallengeType
    let reward: Int
    let step: Int
    let version: Int
    
    init(challengeId: Int,
         title: String,
         desc: String,
         goal: Int,
         type: ChallengeType,
         reward: Int,
         step: Int,
         version: Int
    ){
        self.challengeId = challengeId
        self.title = title
        self.desc = desc
        self.goal = goal
        self.type = type
        self.reward = reward
        self.step = step
        self.version = version
    }
}
