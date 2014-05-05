<?php
class user_model extends CI_Model {

	public $logged_in = FALSE;
	/*private $user;
	private $pass;
	private $email;
	private $account;*/
	
	//$this->session->sess_destroy();=logout
	//http://ellislab.com/codeigniter/user-guide/libraries/sessions.html

	public function __construct()
	{
		$this->load->database();
		//$account=[$user, $pass, $email];
		
		
	}
	
	public function index()
	{
		echo 'index';
	}
	
	public function create_account()
	{
		$this->load->helper('url');

		$user = url_title($this->input->post('user'), '_', TRUE);

		$data = array(
			"username" => $user,
			"password_encrypted" => $this->input->post('pass'),
			"email" =>$this->input->post('email'),
			"logged_in"=>TRUE
			);

		$this->user_model->setAccount($data);
		return $this->db->insert("accounts", $data);
	}

	public function setAccount($data)
	{
        $this->session->set_userdata($data);
        $logged_in = TRUE;
	}

	public function isValidPass($username, $password)
	{
		$query = $this->db->select('password_encrypted')->from('accounts')->where('username',$username)->get();
		if ($query->num_rows() == 0)
		{
			return false;
		}
		else
		{
			foreach($query ->result() as $row) {
				if($password == $row->password) {
					return true;
				}
				
			}
			return false;
		}
		
		/*function valid_login($username,$password) from here http://ellislab.com/forums/viewthread/71712/
		{
    	$query = $this->db->select('password')->from('users')->where('username',$username)->get();
    	if($query->num_rows() == 0)
    	{
        	return false;
        }
    	else
    	{
       		$this->load->library('encrypt');
       		foreach($query->result as $row)
       		{
          	if($this->encrypt->decode($password) == $row->password)
          	{
             	return true;
             }
          }
       	return false;
       	}
    	} */
	}
	//getter methods
	
	public function get_user($user = FALSE)
	{
		if ($user === FALSE)
		{
			$query = $this->db->get('accounts');
			return $query->result_array();
		}

		$query = $this->db->get_where('accounts', array('username' => $user));
		return $query->row()->username;
		
	}

	public function get_pass()
	{
		if ($user === FALSE)
		{
			$query = $this->db->get('accounts');
			return $query->result_array();
		}

		$query = $this->db->get_where('accounts', array('password_encrypted' => $pass));
		return $query->row()->password_encrypted;
	}

	public function get_email()
	{
		if ($user === FALSE)
		{
			$query = $this->db->get('accounts');
			return $query->result_array();
		}

		$query = $this->db->get_where('accounts', array('email' => $email));
		return $query->row()->email;
	}
	
	public function isLoggedIn(){
		return $logged_in;
	}
	
}
