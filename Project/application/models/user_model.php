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

	public function isValidUser($test)
	{
		$query = "SELECT COUNT('iD') FROM eif WHERE user = '$test'";
		if ($query->num_rows() > 0)
		{
			foreach ($query->result() as $row)
			{
				return $this->db->query($row);
			}
		}
		else
		{
			return "USERNAME_DOES_NOT_EXIST";
		}
	}
	
	public function isValidPass($testUser, $testPass)
	{
		$query = "SELECT COUNT('iD') FROM eif WHERE user = '$testUser' AND pass = '$testPass'";
		if ($query->num_rows() > 0)
		{
			foreach ($query->result() as $row)
			{
				return $this->db->query($row);
			}
		}
		else
		{
			return "PASSWRD_IS_INVALID";
		}
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
