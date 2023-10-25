import ballerina/http;


public class GraphQLClient {
    private http:Client httpClient;


    private json mockUser = {};
    private json mockUsers = [];
    private json mockDepartment = {};
    private json mockDepartments = [];
    private json mockDepartmentObjective = {};
    private json mockDepartmentObjectives = [];
    private json mockKPI = {};
    private json mockKPIs = [];

    public function init() returns error? {
        self.httpClient = check new("http://localhost:8080");
        self.initializeMockData();
    }

    // Mock Data
    private function initializeMockData() {
        self.mockUser = {
            "id": "7",
            "firstName": "Markus",
            "lastName": "Shindingeni",
            "jobTitle": "Cleaner",
            "position": "Senior",
            "role": "Employee",
            "department": {
                "id": "5",
                "name": "Engineering"
            },
            "kpis": [
                {
                    "id": "k1",
                    "name": "Completed Projects"
                }
            ]
        };

        self.mockUsers = [
            self.mockUser,
            {
                "id": "8",
                "firstName": "Morale",
                "lastName": "Smith",
                "role": "Supervisor"
            }
        ];

        self.mockDepartmentObjective = {
            "id": "",
            "name": "Improve Efficiency",
            "weight": 1.5,
            "department": {
                "id": "5",
                "name": "Engineering"
            },
            "relatedKPIs": [
                {
                    "id": "k1",
                    "name": "Completed Projects"
                }
            ]
        };

        self.mockDepartmentObjectives = [
            self.mockDepartmentObjective,
            {
                "id": "",
                "name": "Reduce Bugs",
                "weight": 1.0,
                "department": {
                    "id": "5",
                    "name": "QA"
                },
                "relatedKPIs": [
                    {
                        "id": "k2",
                        "name": "Identified Issues"
                    }
                ]
            }
        ];


    self.mockKPI = {
        "id": "k1",
        "user": {
            "id": "1",
            "firstName": "John",
            "lastName": "Doe"
        },
        "name": "Completed Projects",
        "metric": "Number of Projects",
        "unit": "Count",
        "score": 5.0,
        "relatedObjectives": [self.mockDepartmentObjective]
    };

    self.mockKPIs = [
        self.mockKPI,
        {
            "id": "k2",
            "user": {
                "id": "2",
                "firstName": "Jane",
                "lastName": "Smith"
            },
            "name": "Identified Issues",
            "metric": "Number of Issues",
            "unit": "Count",
            "score": 3.5,
            "relatedObjectives": [self.mockDepartmentObjective] // Assuming you want the same objective linked here
        }
    ];

    self.mockDepartment = {
        "id": "101",
        "name": "Engineering",
        "hod": self.mockUser,
        "objectives": [
            {
                "id": "o1",
                "name": "Increase Productivity"
            }
        ],
        "users": [self.mockUser]
    };

    self.mockDepartments = [self.mockDepartment];
    }


}