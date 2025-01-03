//
//  SignupDataService.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/06/08.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import Combine

final class SignupDataService {
    
    @Published var jobs: [SignupModel] = []
    @Published var interests: [SignupModel] = []
    @Published var abilities: [SignupModel] = []
    
    init() {
        getJobs()
        getInterests()
        getAbilities()
    }
    
    // jobs fetch 필요
    func getJobs() {
        let jobsDataFromServer: [SignupModel] = [
            SignupModel(title: "직장인"),
            SignupModel(title: "대학(원)생"),
            SignupModel(title: "프리랜서"),
            SignupModel(title: "기타"),
        ]
        
        self.jobs = jobsDataFromServer
    }
    
    // interests fetch 필요
    func getInterests() {
        let interestsDataFromServer: [SignupModel] = [
            SignupModel(title: "IT / TECH"),
            SignupModel(title: "가전 / 전자"),
            SignupModel(title: "철강"),
            SignupModel(title: "Display"),
            SignupModel(title: "건설 / 건축 / 인테리어"),
            SignupModel(title: "반도체"),
            SignupModel(title: "콘텐츠"),
            SignupModel(title: "2차전지"),
            SignupModel(title: "정유"),
            SignupModel(title: "FMCG /음식 / 소매"),
            SignupModel(title: "석유화학"),
            SignupModel(title: "스마트물류 / 유통"),
            SignupModel(title: "바이오 / 헬스케어"),
            SignupModel(title: "인공지능 / IoT"),
            SignupModel(title: "기타")
        ]
        
        self.interests = interestsDataFromServer
    }
    
    func getAbilities() {
        let abilitiesDataFromServer: [SignupModel] = [
            SignupModel(title: "변화관리"),
            SignupModel(title: "창의 융합"),
            SignupModel(title: "신뢰 구축"),
            SignupModel(title: "협상"),
            SignupModel(title: "경청, 조언, 상담"),
            SignupModel(title: "문제 해결(트러블슈팅)"),
            SignupModel(title: "집중력"),
            SignupModel(title: "업무추진"),
            SignupModel(title: "비즈니스 운영, 관리"),
            SignupModel(title: "기획, 전략 설정"),
            SignupModel(title: "커뮤니케이션"),
            SignupModel(title: "회계, 예산관리"),
            SignupModel(title: "세일즈(판매)"),
            SignupModel(title: "인적자원운영"),
        ]
        
        self.abilities = abilitiesDataFromServer
    }
}
