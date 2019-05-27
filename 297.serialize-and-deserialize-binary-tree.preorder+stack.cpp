/**
 * Definition for a binary tree node.
 * struct TreeNode {
 *   int val;
 *   TreeNode *left;
 *   TreeNode *right;
 *   TreeNode(int x) : val(x), left(NULL), right(NULL) {}
 * };
 */
class Codec {
public:

  // Encodes a tree to a single string.
  string serialize(TreeNode* root) {
    if (!root) {
      return "#";
    }
    
    TreeNode* cur = nullptr;
    stack<TreeNode*> mystack;
    string result;
    
    mystack.push(root);
    while (!mystack.empty()) {
      cur = mystack.top();
      mystack.pop();
      if (!result.empty()) {
        result += ',';
      }
      result += cur ? to_string(cur->val) : "#";
      if (cur) {
        mystack.push(cur->right);
        mystack.push(cur->left);        
      }
    }
    
    return result;
  }

  // Decodes your encoded data to tree.
  TreeNode* deserialize(string data) {
    istringstream is(data);
    return deserialize(is);
  }
  
private:
  TreeNode* deserialize(istringstream& is) {
    // 1,2,#,#,3,4,#,#,5,#,#
    // 1 2 # # #
    // 1 #
    string val;
    getline(is, val, ',');
    
    if (val == "#") {
      return nullptr;
    }
    
    TreeNode* root = new TreeNode(stoi(val));
    TreeNode* cur = nullptr, *top = nullptr;
    stack<TreeNode*> mystack;
    
    mystack.push(root);
    while (getline(is, val, ',')) {
      if (val != "#") {
        mystack.push(new TreeNode(stoi(val)));
      } else {
        cur = nullptr;
        while (!mystack.empty() && !mystack.top()) {
          mystack.pop();
          top = mystack.top();
          mystack.pop();
          top->right = cur;
          cur = top;
        }
        if (!mystack.empty()) {
          mystack.top()->left = cur;
        }
        mystack.push(nullptr);
      }
    }
    
    return root;
  }
};

// Your Codec object will be instantiated and called as such:
// Codec codec;
// codec.deserialize(codec.serialize(root));
