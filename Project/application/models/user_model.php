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
	
	public function logOut()
	{
		$logged_in = FALSE;
		$this->session->sess_destroy();
	}

	public function isAccount($username, $password)
	{
		$query = $this->db->select('password_encrypted')->from('accounts')->where('username',$username)->get();
		if ($query->num_rows() == 0)
		{
			return false;
		}
		else
		{
			$row = $query->row(); 
			if($password == $row->password_encrypted) {
				return true;
			}
			return false;
		}
	}
	
	public function updateHighscore($highscore, $username){
		/*$score = $highscore;
		$data = array( "highscore" => $score );
		$this->db->update('accounts', $data, "username = $username");*/
		//$this->db->query("UPDATE accounts SET highscore = $highscore WHERE username = $username");
		$this->db->query("UPDATE accounts SET highscore = ? WHERE username = ?", array($highscore, $username));
	}
	//getter methods
	
	public function get_email($user)
	{
		if ($user === FALSE)
		{
			$query = $this->db->get('accounts');
			return $query->result_array();
		}

		$query = $this->db->get_where('accounts', array('username' => $user));
		return $query->row()->email;
	}
	
	public function isLoggedIn(){
		return $logged_in;
	}
	
}
