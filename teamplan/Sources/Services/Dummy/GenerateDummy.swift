//
//  GenerateDummy.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/27.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class GenerateDummy{
    
    
    //===============================
    // MARK: - Dummy User
    //===============================
    func createDummyUser() -> UserObject{
        return UserObject(
            user_id: "test_apple",
            user_fb_id: "null",
            user_email: "testAcc@apple.com",
            user_name: "dummyUser",
            user_social_type: "apple",
            user_status: .active,
            user_created_at: Date(),
            user_login_at: Date().addingTimeInterval(Double(1) * 60 * 30),
            user_updated_at: Date()
        )
    }
    
    
    //===============================
    // MARK: - Dummy Project
    //===============================
    func createDummyProject() -> [ProjectObject]{
        
        var projectAry: [ProjectObject] = []
        
        for i in 1...5{
            var todoAry: [TodoObject] = []
            
            // Struct Dummy Todo
            for j in 1...10 {
                let todo = TodoObject(
                    todo_id: Int64(i * 10 + j),
                    todo_desc: "Todo: \(j) for Project: \(i)",
                    todo_pinned: false,
                    todo_status: true,
                    todo_registed_at: Date(),
                    todo_changed_at: Date(),
                    todo_updated_at: Date()
                )
                todoAry.append(todo)
            }
            
            // Struct Dummy Project
            // add 1 weak for testing sort
            let projInterval = Double(i) * 60 * 60 * 24 * 7
            let project = ProjectObject(
                proj_id: Int64(i),
                proj_title: "Project: \(i)",
                proj_started_at: Date(),
                proj_deadline: Date().addingTimeInterval(projInterval),
                proj_finished: false,
                proj_todo: todoAry,
                proj_todo_registed: 10,
                proj_todo_finished: 0,
                proj_registed_at: Date(),
                proj_changed_at: Date(),
                proj_finished_at: Date()
            )
            projectAry.append(project)
        }
        return projectAry
    }
    
    //===============================
    // MARK: - Dummy MyChallenge
    //===============================
    func createDummyMyChallenge() -> [ChallengeObject]{
        
        var myChallengeAry: [ChallengeObject] = []
        let challengeType: [ChallengeType] = [.unkown, .term, .finProj, .totTodo]
        
        for i in 1...3{
            let selectType = challengeType[i]
            let challenge = ChallengeObject(
                chlg_id: Int64(i),
                chlg_type: selectType,
                chlg_title: "MyChallenge: \(i)",
                chlg_desc: "MyChallenge Desc: \(i)",
                chlg_goal: Int64(i * 10),
                chlg_reward: Int(i + 5),
                chlg_step: Int(i),
                chlg_selected: true,
                chlg_status: true,
                chlg_lock: false,
                chlg_selected_at: Date(),
                chlg_unselected_at: Date(),
                chlg_finished_at: Date()
            )
            myChallengeAry.append(challenge)
        }
        return myChallengeAry
    }
}
