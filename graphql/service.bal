import ballerina/graphql;
import ballerina/sql;
// import ballerinax/java.jdbc;  //for when using the local mysql instance
import ballerinax/mysql;



mysql:Client p1DB = check new("localhost", "root", "root", "assignment-2-p1", 3307);

service /graphql on new graphql:Listener(8080) {


        // Statements
    resource function get user(int id) returns User|error {
        sql:ParameterizedQuery query = `SELECT * FROM Users WHERE id = ${id}`;
        stream<User, sql:Error?> resultStream = p1DB->query(query, User);

        record {| User value; |}? result = check resultStream.next();

        // Close the stream
        var closeResult = resultStream.close();

        if (closeResult is error) {
            return closeResult;
        }

        if (result is record {| User value; |}) {
            return result.value;
        } else {
            return error("User not found");
        }
    }
    

    //fecth department by ID
    resource function get department(int id) returns Department|error {
        sql:ParameterizedQuery depQuery = `SELECT * FROM Departments WHERE id = ${id}`;
        stream<Department, sql:Error?> depStream = p1DB->query(depQuery);

        record {| Department value; |}? depResult = check depStream.next();

        if (depResult is record {| Department value; |}) {
            Department dept = depResult.value;

            // If the hodId is present in the department, fetch the corresponding User
            if (dept.hodId is int) {
                sql:ParameterizedQuery hodQuery = `SELECT * FROM Users WHERE id = ${dept.hodId}`;
                stream<User, sql:Error?> hodStream = p1DB->query(hodQuery, User);
                record {| User value; |}? hodResult = check hodStream.next();
                if (hodResult is record {| User value; |}) {
                    dept.hod = hodResult.value;
                }
            }
            
            return dept;
        } else {
            return error("Requested Department Not Found");
        }
    }


    //Get department KPI Objective by id key
    resource function get departmentObjective(int id) returns DepartmentObjective|error {
        sql:ParameterizedQuery objQuery = `SELECT * FROM DepartmentObjectives WHERE id = ${id}`;
        stream<DepartmentObjective, sql:Error?> objStream = p1DB->query(objQuery);

        record {| DepartmentObjective value; |}? objResult = check objStream.next();

        if (objResult is record {| DepartmentObjective value; |}) {
            DepartmentObjective obj = objResult.value;

            // Get related KPIs for this objective
            sql:ParameterizedQuery kpiQuery = `
                SELECT KPIs.* 
                FROM KPIs 
                JOIN ObjectiveKPIRelation ON KPIs.id = ObjectiveKPIRelation.kpiId
                WHERE ObjectiveKPIRelation.objectiveId = ${id}`;
            stream<KPI, sql:Error?> kpiStream = p1DB->query(kpiQuery);
            KPI[] kpis = [];
            error? kpiErr = kpiStream.forEach(function(KPI kpi) {
                kpis.push(kpi);
            });
            if (kpiErr is error) {
                return kpiErr;
            }
            obj.relatedKPIs = kpis;

            return obj;
        } else {
            return error("DepartmentObjective not found");
        }
    }


    //Get KPI by ID
    resource function get kpi(int id) returns KPI|error {
        sql:ParameterizedQuery kpiQuery = `SELECT * FROM KPIs WHERE id = ${id}`;
        stream<KPI, sql:Error?> kpiStream = p1DB->query(kpiQuery);

        record {| KPI value; |}? kpiResult = check kpiStream.next();

        if (kpiResult is record {| KPI value; |}) {
            KPI kpi = kpiResult.value;

            // Get related objectives for this KPI
            sql:ParameterizedQuery objQuery = `
                SELECT DepartmentObjectives.* 
                FROM DepartmentObjectives 
                JOIN ObjectiveKPIRelation ON DepartmentObjectives.id = ObjectiveKPIRelation.objectiveId
                WHERE ObjectiveKPIRelation.kpiId = ${id}`;
            stream<DepartmentObjective, sql:Error?> objStream = p1DB->query(objQuery);

            DepartmentObjective[] objs = [];
            error? objStreamErr = objStream.forEach(function(DepartmentObjective obj) {
                objs.push(obj);
            });

            if (objStreamErr is error) {
                return objStreamErr;
            }

            kpi.relatedObjectives = objs;

            return kpi;
        } else {
            return error("KPI not found");
        }
    }


    //Get all users
    resource function get users() returns User[]|error {
        sql:ParameterizedQuery userQuery = `SELECT * FROM Users`;
        stream<User, sql:Error?> userStream = p1DB->query(userQuery);
        User[] users = [];
        
        // Loop through the user stream to populate the users array
        error? e = userStream.forEach(function(User usr) {
            users.push(usr);
        });
        
        if (e is error) {
            return e;
        }
        return users;
    }



    //Get all departments
    resource function get departments() returns Department[]|error {
        sql:ParameterizedQuery depQuery = `SELECT * FROM Departments`;
        stream<Department, sql:Error?> depStream = p1DB->query(depQuery);
        
        Department[] departments = [];
        // Loop through the department stream to populate the departments array
        error? err = depStream.forEach(function(Department dept) {
            departments.push(dept);
        });
        
        if (err is error) {
            return err;
        }
        return departments;
    }


    //Get all department objectives
    resource function get departmentObjectives() returns DepartmentObjective[]|error {
        sql:ParameterizedQuery objQuery = `SELECT * FROM DepartmentObjectives`;
        stream<DepartmentObjective, sql:Error?> objStream = p1DB->query(objQuery);

        DepartmentObjective[] objectives = [];
        
        // Loop through the stream to populate the objectives array
        error? err = objStream.forEach(function(DepartmentObjective obj) {
            objectives.push(obj);
        });
        
        if (err is error) {
            return err;
        }
        return objectives;
    }



    //Get all KPIs
    resource function get kpis() returns KPI[]|error {
        sql:ParameterizedQuery kpiQuery = `SELECT * FROM KPIs`;
        stream<KPI, sql:Error?> kpiStream = p1DB->query(kpiQuery);

        KPI[] kpis = [];
        
        // Loop through the stream to populate the kpis array
        error? err = kpiStream.forEach(function(KPI kpi) {
            kpis.push(kpi);
        });
        
        if (err is error) {
            return err;
        }
        return kpis;
    }
    //MUTATIONS

    resource function get createUser(string firstName, string lastName, string jobTitle, string position, UserRole role, int departmentId) returns User|error {
        
        sql:ParameterizedQuery query = `INSERT INTO Users(firstName, lastName, jobTitle, position, role, departmentId) VALUES(${firstName}, ${lastName}, ${jobTitle}, ${position}, ${role}, ${departmentId})`;
        
        var response = p1DB->execute(query);
        
        if (response is sql:ExecutionResult) {
            int userId;
            if (response.lastInsertId is int) {
                userId = <int>response.lastInsertId;
            } else {
                return error("Expected lastInsertId to be of type int");
            }
            
            User newUser = {
                id: userId,
                firstName: firstName,
                lastName: lastName,
                jobTitle: jobTitle,
                position: position,
                role: role,
                department: { id: departmentId, name: "" } 
            };
            return newUser;
        } else {
            return response;
        }
    }

    // update user mutation
    resource function get updateUser(int id, string firstName, string lastName, string jobTitle, string position, UserRole role, int departmentId) returns User|error {
        
        sql:ParameterizedQuery query = `UPDATE Users SET firstName=${firstName}, lastName=${lastName}, jobTitle=${jobTitle}, position=${position}, role=${role}, departmentId=${departmentId} WHERE id=${id}`;
        
        var response = p1DB->execute(query);
        
        if (response is sql:ExecutionResult) {
            User updatedUser = {
                id: id,
                firstName: firstName,
                lastName: lastName,
                jobTitle: jobTitle,
                position: position,
                role: role,
                department: { id: departmentId, name: "" } // Addressing the missing field, but you might need to fetch the actual department name.
            };
            return updatedUser;
        } else {
            return error("Failed to update user record");
        }
    }


    resource function get deleteUser(int id) returns boolean|error {
        
        sql:ParameterizedQuery query = `DELETE FROM Users WHERE id=${id}`;
        
        var response = p1DB->execute(query);
        
        if (response is sql:ExecutionResult) {
            return true;
        } else {
            return error("Failed to delete user");
        }
    }


    resource function get createDepartment(string name) returns Department|error {
        
        sql:ParameterizedQuery query = `INSERT INTO Departments(name) VALUES(${name})`;
        
        var response = p1DB->execute(query);
        
        if (response is sql:ExecutionResult) {
            int departmentId;
            if (response.lastInsertId is int) {
                departmentId = <int>response.lastInsertId;
            } else {
                return error("Expected lastInsertId to be of type int");
            }

            Department newDepartment = {
                id: departmentId,
                name: name
            };
            return newDepartment;
        } else {
            return error("Failed to create department");
        }
    }


    resource function get updateDepartment(int id, string name) returns Department|error {
        
        sql:ParameterizedQuery query = `UPDATE Departments SET name=${name} WHERE id=${id}`;
        
        var response = p1DB->execute(query);
        
        if (response is sql:ExecutionResult) {
            Department updatedDepartment = {
                id: id,
                name: name
            };
            return updatedDepartment;
        } else {
            return error("Failed to update department");
        }
    }


    resource function get deleteDepartment(int id) returns boolean|error {
        
        sql:ParameterizedQuery query = `DELETE FROM Departments WHERE id=${id}`;
        
        var response = p1DB->execute(query);
        
        if (response is sql:ExecutionResult) {
            return true;
        } else {
            return error("Failed to delete department");
        }
    }


    resource function get createDepartmentObjective(string name, float weight, int departmentId) returns DepartmentObjective|error {
        
        sql:ParameterizedQuery query = `INSERT INTO DepartmentObjectives(name, weight, departmentId) VALUES(${name}, ${weight}, ${departmentId})`;
        
        var response = p1DB->execute(query);
        
        if (response is sql:ExecutionResult) {
            int objectiveId;
            if (response.lastInsertId is int) {
                objectiveId = <int>response.lastInsertId;
            } else {
                return error("Expected lastInsertId to be of type int");
            }

            DepartmentObjective newObjective = {
                id: objectiveId,
                name: name,
                weight: weight,
                department: { id: departmentId, name: "" } // I'm assuming the department's name is not known at this point, so using an empty string. You may need to fetch the actual name or adjust this.
            };
            return newObjective;
        } else {
            return error("Failed to create department objective");
        }
    }


    resource function get updateDepartmentObjective(int id, string name, float weight) returns DepartmentObjective|error {
        
        sql:ParameterizedQuery query = `UPDATE DepartmentObjectives SET name=${name}, weight=${weight} WHERE id=${id}`;
        
        var response = p1DB->execute(query);
        
        if (response is sql:ExecutionResult) {
            return {id: id, name: name, weight: weight};
        } else {
            return error("Failed to update department objective");
        }
    }


    resource function get deleteDepartmentObjective(int id) returns boolean|error {
        
        sql:ParameterizedQuery query = `DELETE FROM DepartmentObjectives WHERE id=${id}`;
        
        var response = p1DB->execute(query);
        
        if (response is sql:ExecutionResult) {
            return true;
        } else {
            return error("Failed to delete department objective");
        }
    }


    resource function get createKPI(int userId, string name, string metric, string unit) returns KPI|error {
        sql:ParameterizedQuery query = `INSERT INTO KPIs(userId, name, metric, unit) VALUES(${userId}, ${name}, ${metric}, ${unit})`;
        var response = p1DB->execute(query);
        
        if (response is sql:ExecutionResult) {
            KPI newKPI = {
                id: <int>response.lastInsertId,
                user: {id: userId,firstName: "", lastName: "", role: "Employee"}, // We're only setting the 'id' field here. To fetch other User fields, another DB call is needed.
                name: name,
                metric: metric,
                unit: unit,
                score: () // This is optional and hasn't been provided. Hence it will be nil.
            };
            return newKPI;
        } else {
            return error("Failed to create KPI");
        }
    }



    resource function get updateKPI(int id, int userId, string name, string metric, string unit, float score) returns KPI|error {
        sql:ParameterizedQuery query = `UPDATE KPIs SET userId=${userId}, name=${name}, metric=${metric}, unit=${unit}, score=${score} WHERE id=${id}`;
        var response = p1DB->execute(query);
        
        if (response is sql:ExecutionResult) {
            KPI updatedKPI = {
                id: id,
                user: {id: userId,firstName: "", lastName: "", role: "Employee"},  // Only setting the 'id' field for user. To fetch other User fields, another DB call would be needed.
                name: name,
                metric: metric,
                unit: unit,
                score: score
            };
            return updatedKPI;
        } else {
            return error("Failed to update KPI");
        }
    }


    resource function get deleteKPI(int id) returns boolean|error {
        sql:ParameterizedQuery query = `DELETE FROM KPIs WHERE id=${id}`;
        var response = p1DB->execute(query);
        
        if (response is sql:ExecutionResult) {
            return true;
        } else {
            return error("Failed to delete KPI");
        }
    }




}

public type User record {
    int id;
    string firstName;
    string lastName;
    string jobTitle?;
    string position?;
    UserRole role;
    Department department?;
};

public type Department record {
    int id;
    string name;
    int hodId?;
    User hod?;
    DepartmentObjective[] objectives?;
    User[] users?;
};


public type DepartmentObjective record {
    int id;
    string name;
    float weight;
    Department department?;
    KPI[] relatedKPIs?;
};

public type KPI record {
    int id;
    User user;
    string name;
    string metric?;
    string unit?;
    float score?;
    DepartmentObjective[] relatedObjectives?;
};

public enum UserRole {
    HoD,
    Supervisor,
    Employee
};

// For demonstration, some mock data
User mockUser = {
    id: 1,
    firstName: "John",
    lastName: "Doe",
    role: HoD
};

Department mockDepartment = {
    id: 1,
    name: "Computer Science",
    hod: mockUser
};

DepartmentObjective mockObjective = {
    id: 1,
    name: "Improve Research",
    weight: 75.0,
    department: mockDepartment
};

KPI mockKPI = {
    id: 1,
    user: mockUser,
    name: "Research Papers Published",
    metric: "Number",
    unit: "Papers",
    score: 4.5,
    relatedObjectives: [mockObjective]
};

// jdbc:Client p1DB = check new ("jdbc:mysql://localhost:3307/assignment-2-p1", "root", "root");
