// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract ToDoList{
    address owner;
    uint256[] taskIds;

    enum TaskStatus{
        NOT_FINISHED,
        DONE,
        FAILED
    }
    
    struct Task{
        address assigner;
        address assignee;
        uint256 deadline;
        string  taskName;
        TaskStatus status;
    }

    mapping(uint256 => Task) tasks;

    constructor(){
        owner = msg.sender;
    }
    
    // Function to add a task / modify previous task into the Smart Contract
    function addTask(address _assignee, uint256 _taskId, uint256 _deadline, string memory _taskName)
    public payable{
        // Require user to pay 0.001 ETH for manager fee
        require(msg.value >= (0.001 ether), "Must pay 0.001 ETH to add a new task");
        // Check if the task has existed before
        if(tasks[_taskId].assigner != address(0)){
            require(msg.sender == tasks[_taskId].assigner, "Only Previous Assigner can modify the contract");
        }
        else{
            taskIds.push(_taskId);
        }

        // Add the task details to Smart Contract 
        tasks[_taskId] = Task(
            msg.sender, 
            _assignee,
            block.timestamp + _deadline, 
            _taskName, 
            TaskStatus.NOT_FINISHED
        );
    }

    // Function to check the status of an existing task in the Smart Contract
    function checkStatus(uint256 _taskId) 
    public view returns (string memory, string memory, uint256){
        string memory status;
        if(tasks[_taskId].status == TaskStatus.DONE){
            status = "Done";
        }
        else if(tasks[_taskId].status == TaskStatus.NOT_FINISHED){
            status = "Not Finished";
        }
        else if(tasks[_taskId].status == TaskStatus.FAILED){
            status = "Failed";
        }
        return(
            tasks[_taskId].taskName, 
            status, 
            (checkDeadlineValidity(_taskId) ? tasks[_taskId].deadline - block.timestamp : 0 )
        );
    }

    // Function to check how many unfinished task
    function countAssignedTasks() internal view returns (uint256){
        uint256 count = 0;
        for(uint i=0; i<taskIds.length; i++){
            if(tasks[taskIds[i]].assignee == msg.sender && tasks[taskIds[i]].status == TaskStatus.NOT_FINISHED){
                count++;
            }
        }
        return count;
    }
    
    // Function to check the existing task of user
    function findAssignedTasks() public view returns (uint256[] memory){
        uint256 count = countAssignedTasks();
        uint256 index = 0;
        uint256[] memory assignedTasks = new uint256[](count);

        for(uint i=0; i<taskIds.length; i++){
            if(tasks[taskIds[i]].assignee == msg.sender && tasks[taskIds[i]].status == TaskStatus.NOT_FINISHED){
                assignedTasks[index] = taskIds[i];
                index++;
            }
        }
        return assignedTasks;
    }

    // Function to update the deadline of a task
    function addDeadline(uint256 _taskId, uint256 _addedTime) public onlyAssigner(_taskId){
        if(!checkDeadlineValidity(_taskId)){
            tasks[_taskId].deadline = block.timestamp;
        }
        tasks[_taskId].deadline += _addedTime;
    } 

    // Function for Assignee to complete the task
    function completeTask(uint256 _taskId) public onlyAssignee(_taskId){
        bool success = checkDeadlineValidity(_taskId);
        if(success){
            tasks[_taskId].status = TaskStatus.DONE;
        }else{
            tasks[_taskId].status = TaskStatus.FAILED;
        }
    }

    // Function to check whether the task hasn't exceeded the Deadline
    function checkDeadlineValidity(uint256 _taskId) internal view returns(bool){
        return tasks[_taskId].deadline > block.timestamp;
    }

    // Function to withdraw the Smart Contract Balance
    function withdraw() public onlyOwner{
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Withdrawal Failed");
    }

    modifier onlyAssigner(uint256 _taskId){
        require(msg.sender == tasks[_taskId].assigner, "Only Allowed for Task Assigner");
        _;
    }
    modifier onlyAssignee(uint256 _taskId){
        require(msg.sender == tasks[_taskId].assignee, "Only Allowed for Task Assignee");
        _;
    }
    modifier onlyOwner(){
        require(msg.sender == owner, "Only Allowed for Contract Creator");
        _;
    }
}